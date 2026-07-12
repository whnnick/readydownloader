#include <windows.h>
#include <commctrl.h>
#include <shlobj.h>
#include <urlmon.h>

#include <algorithm>
#include <atomic>
#include <cctype>
#include <fstream>
#include <iomanip>
#include <memory>
#include <map>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "YtDlpService.h"

#pragma comment(lib, "Comctl32.lib")
#pragma comment(lib, "Shell32.lib")
#pragma comment(lib, "Urlmon.lib")

namespace {

constexpr int IDC_URL = 1001;
constexpr int IDC_YTDLP = 1002;
constexpr int IDC_BROWSE_YTDLP = 1003;
constexpr int IDC_DOWNLOAD_YTDLP = 1004;
constexpr int IDC_OUTPUT = 1005;
constexpr int IDC_BROWSE_OUTPUT = 1006;
constexpr int IDC_FETCH = 1007;
constexpr int IDC_DOWNLOAD = 1008;
constexpr int IDC_FORMATS = 1009;
constexpr int IDC_LOG = 1010;
constexpr int IDC_COOKIE_CHECK = 1011;
constexpr int IDC_COOKIE_BROWSER = 1012;
constexpr int IDC_COOKIE_FILE = 1013;
constexpr int IDC_BROWSE_COOKIE_FILE = 1014;
constexpr int IDC_EXTRA_ARGS = 1015;
constexpr int IDC_PROXY_DIRECT = 1016;
constexpr int IDC_PROXY_SYSTEM = 1017;
constexpr int IDC_PROXY_CUSTOM = 1018;
constexpr int IDC_PROXY_URL = 1019;
constexpr int IDC_DETAILED_LOG = 1020;

constexpr UINT WM_APP_LOG = WM_APP + 1;
constexpr UINT WM_APP_FORMATS_READY = WM_APP + 2;
constexpr UINT WM_APP_WORK_DONE = WM_APP + 3;
constexpr UINT WM_APP_DEBUG_LOG = WM_APP + 4;
constexpr UINT WM_APP_PROGRESS_LOG = WM_APP + 5;

HWND g_urlEdit = nullptr;
HWND g_ytdlpEdit = nullptr;
HWND g_outputEdit = nullptr;
HWND g_fetchButton = nullptr;
HWND g_downloadButton = nullptr;
HWND g_formatsList = nullptr;
HWND g_logEdit = nullptr;
HWND g_cookieCheck = nullptr;
HWND g_cookieBrowser = nullptr;
HWND g_cookieFileEdit = nullptr;
HWND g_extraArgsEdit = nullptr;
HWND g_proxyDirect = nullptr;
HWND g_proxySystem = nullptr;
HWND g_proxyCustom = nullptr;
HWND g_proxyUrlEdit = nullptr;
HWND g_detailedLogCheck = nullptr;
int g_progressLineStart = -1;
std::unique_ptr<YtDlpService> g_ytDlpService;

HMENU ControlId(int id) {
    return reinterpret_cast<HMENU>(static_cast<INT_PTR>(id));
}

struct FormatOption {
    std::wstring id;
    std::wstring ext;
    std::wstring resolution;
    std::wstring width;
    std::wstring heightText;
    std::wstring filesize;
    std::wstring note;
    std::wstring fps;
    std::wstring vcodec;
    std::wstring acodec;
    std::wstring tbr;
    int height = 0;
};

std::vector<FormatOption> g_formats;

struct JsonValue {
    enum class Type { Null, Bool, Number, String, Array, Object };

    Type type = Type::Null;
    bool boolValue = false;
    double numberValue = 0.0;
    std::wstring stringValue;
    std::vector<JsonValue> arrayValue;
    std::map<std::wstring, JsonValue> objectValue;

    const JsonValue* get(const std::wstring& key) const {
        auto it = objectValue.find(key);
        return it == objectValue.end() ? nullptr : &it->second;
    }
};

class JsonParser {
public:
    explicit JsonParser(const std::wstring& text) : text_(text) {}

    bool parse(JsonValue& out) {
        skipWhitespace();
        if (!parseValue(out)) {
            return false;
        }
        skipWhitespace();
        return pos_ == text_.size();
    }

private:
    const std::wstring& text_;
    size_t pos_ = 0;

    void skipWhitespace() {
        while (pos_ < text_.size() && iswspace(text_[pos_])) {
            ++pos_;
        }
    }

    bool consume(wchar_t c) {
        if (pos_ < text_.size() && text_[pos_] == c) {
            ++pos_;
            return true;
        }
        return false;
    }

    bool parseValue(JsonValue& out) {
        skipWhitespace();
        if (pos_ >= text_.size()) {
            return false;
        }

        wchar_t c = text_[pos_];
        if (c == L'{') {
            return parseObject(out);
        }
        if (c == L'[') {
            return parseArray(out);
        }
        if (c == L'"') {
            out.type = JsonValue::Type::String;
            return parseString(out.stringValue);
        }
        if (c == L't') {
            return parseLiteral(L"true", [&] {
                out.type = JsonValue::Type::Bool;
                out.boolValue = true;
            });
        }
        if (c == L'f') {
            return parseLiteral(L"false", [&] {
                out.type = JsonValue::Type::Bool;
                out.boolValue = false;
            });
        }
        if (c == L'n') {
            return parseLiteral(L"null", [&] {
                out.type = JsonValue::Type::Null;
            });
        }
        if (c == L'-' || iswdigit(c)) {
            out.type = JsonValue::Type::Number;
            return parseNumber(out.numberValue);
        }
        return false;
    }

    template <typename Fn>
    bool parseLiteral(const wchar_t* literal, Fn apply) {
        size_t len = wcslen(literal);
        if (text_.compare(pos_, len, literal) != 0) {
            return false;
        }
        pos_ += len;
        apply();
        return true;
    }

    bool parseObject(JsonValue& out) {
        if (!consume(L'{')) {
            return false;
        }
        out.type = JsonValue::Type::Object;
        skipWhitespace();
        if (consume(L'}')) {
            return true;
        }

        while (pos_ < text_.size()) {
            std::wstring key;
            if (!parseString(key)) {
                return false;
            }
            skipWhitespace();
            if (!consume(L':')) {
                return false;
            }
            JsonValue value;
            if (!parseValue(value)) {
                return false;
            }
            out.objectValue.emplace(std::move(key), std::move(value));
            skipWhitespace();
            if (consume(L'}')) {
                return true;
            }
            if (!consume(L',')) {
                return false;
            }
            skipWhitespace();
        }
        return false;
    }

    bool parseArray(JsonValue& out) {
        if (!consume(L'[')) {
            return false;
        }
        out.type = JsonValue::Type::Array;
        skipWhitespace();
        if (consume(L']')) {
            return true;
        }

        while (pos_ < text_.size()) {
            JsonValue value;
            if (!parseValue(value)) {
                return false;
            }
            out.arrayValue.push_back(std::move(value));
            skipWhitespace();
            if (consume(L']')) {
                return true;
            }
            if (!consume(L',')) {
                return false;
            }
            skipWhitespace();
        }
        return false;
    }

    bool parseString(std::wstring& out) {
        if (!consume(L'"')) {
            return false;
        }
        out.clear();
        while (pos_ < text_.size()) {
            wchar_t c = text_[pos_++];
            if (c == L'"') {
                return true;
            }
            if (c != L'\\') {
                out.push_back(c);
                continue;
            }
            if (pos_ >= text_.size()) {
                return false;
            }
            wchar_t esc = text_[pos_++];
            switch (esc) {
            case L'"': out.push_back(L'"'); break;
            case L'\\': out.push_back(L'\\'); break;
            case L'/': out.push_back(L'/'); break;
            case L'b': out.push_back(L'\b'); break;
            case L'f': out.push_back(L'\f'); break;
            case L'n': out.push_back(L'\n'); break;
            case L'r': out.push_back(L'\r'); break;
            case L't': out.push_back(L'\t'); break;
            case L'u':
                if (pos_ + 4 > text_.size()) {
                    return false;
                } else {
                    wchar_t* end = nullptr;
                    std::wstring hex = text_.substr(pos_, 4);
                    long code = wcstol(hex.c_str(), &end, 16);
                    if (end == hex.c_str() || *end != L'\0') {
                        return false;
                    }
                    out.push_back(static_cast<wchar_t>(code));
                    pos_ += 4;
                }
                break;
            default:
                return false;
            }
        }
        return false;
    }

    bool parseNumber(double& out) {
        size_t start = pos_;
        if (text_[pos_] == L'-') {
            ++pos_;
        }
        while (pos_ < text_.size() && iswdigit(text_[pos_])) {
            ++pos_;
        }
        if (pos_ < text_.size() && text_[pos_] == L'.') {
            ++pos_;
            while (pos_ < text_.size() && iswdigit(text_[pos_])) {
                ++pos_;
            }
        }
        if (pos_ < text_.size() && (text_[pos_] == L'e' || text_[pos_] == L'E')) {
            ++pos_;
            if (pos_ < text_.size() && (text_[pos_] == L'+' || text_[pos_] == L'-')) {
                ++pos_;
            }
            while (pos_ < text_.size() && iswdigit(text_[pos_])) {
                ++pos_;
            }
        }
        std::wstring number = text_.substr(start, pos_ - start);
        wchar_t* end = nullptr;
        out = wcstod(number.c_str(), &end);
        return end != number.c_str() && *end == L'\0';
    }
};

std::wstring Utf8ToWide(const std::string& text) {
    if (text.empty()) {
        return {};
    }
    int length = MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
    if (length <= 0) {
        length = MultiByteToWideChar(CP_ACP, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
        std::wstring fallback(length, L'\0');
        MultiByteToWideChar(CP_ACP, 0, text.data(), static_cast<int>(text.size()), fallback.data(), length);
        return fallback;
    }
    std::wstring result(length, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), result.data(), length);
    return result;
}

std::wstring GetWindowTextString(HWND hwnd) {
    int length = GetWindowTextLengthW(hwnd);
    std::wstring text(length + 1, L'\0');
    GetWindowTextW(hwnd, text.data(), length + 1);
    text.resize(length);
    return text;
}

void SetWindowTextString(HWND hwnd, const std::wstring& text) {
    SetWindowTextW(hwnd, text.c_str());
}

void PostLog(HWND hwnd, const std::wstring& text) {
    PostMessageW(hwnd, WM_APP_LOG, 0, reinterpret_cast<LPARAM>(new std::wstring(text)));
}

void PostUserLog(HWND hwnd, const std::wstring& text) {
    PostMessageW(hwnd, WM_APP_LOG, 0, reinterpret_cast<LPARAM>(new std::wstring(text)));
}

void PostDebugLog(HWND hwnd, const std::wstring& text) {
    PostMessageW(hwnd, WM_APP_DEBUG_LOG, 0, reinterpret_cast<LPARAM>(new std::wstring(text)));
}

void PostProgressLog(HWND hwnd, const std::wstring& text) {
    PostMessageW(hwnd, WM_APP_PROGRESS_LOG, 0, reinterpret_cast<LPARAM>(new std::wstring(text)));
}

std::wstring QuoteArg(const std::wstring& arg) {
    std::wstring quoted = L"\"";
    size_t backslashes = 0;
    for (wchar_t c : arg) {
        if (c == L'\\') {
            ++backslashes;
        } else if (c == L'"') {
            quoted.append(backslashes * 2 + 1, L'\\');
            quoted.push_back(c);
            backslashes = 0;
        } else {
            quoted.append(backslashes, L'\\');
            backslashes = 0;
            quoted.push_back(c);
        }
    }
    quoted.append(backslashes * 2, L'\\');
    quoted.push_back(L'"');
    return quoted;
}

void WriteSetting(const wchar_t* key, const std::wstring& value);

ProxyMode GetSelectedProxyMode() {
    if (g_proxyDirect && SendMessageW(g_proxyDirect, BM_GETCHECK, 0, 0) == BST_CHECKED) {
        return ProxyMode::Direct;
    }
    if (g_proxySystem && SendMessageW(g_proxySystem, BM_GETCHECK, 0, 0) == BST_CHECKED) {
        return ProxyMode::System;
    }
    return ProxyMode::Custom;
}

std::wstring ProxyModeName(ProxyMode mode) {
    switch (mode) {
    case ProxyMode::Direct: return L"直连模式";
    case ProxyMode::System: return L"系统代理模式";
    case ProxyMode::Custom: return L"自定义代理模式";
    default: return L"未知";
    }
}

void ApplyProxyOptions() {
    if (!g_ytDlpService) {
        return;
    }
    ProxyMode mode = GetSelectedProxyMode();
    std::wstring proxyUrl = g_proxyUrlEdit ? GetWindowTextString(g_proxyUrlEdit) : L"";
    g_ytDlpService->SetProxyOptions(mode, proxyUrl);
}

bool IsDetailedLogEnabled() {
    return g_detailedLogCheck && SendMessageW(g_detailedLogCheck, BM_GETCHECK, 0, 0) == BST_CHECKED;
}

std::wstring Trim(const std::wstring& value) {
    size_t first = 0;
    while (first < value.size() && iswspace(value[first])) {
        ++first;
    }
    size_t last = value.size();
    while (last > first && iswspace(value[last - 1])) {
        --last;
    }
    return value.substr(first, last - first);
}

std::vector<std::wstring> SplitTextLines(std::wstring& pending, const std::wstring& chunk) {
    pending += chunk;
    std::vector<std::wstring> lines;
    size_t pos = 0;
    while (pos < pending.size()) {
        size_t next = pending.find_first_of(L"\r\n", pos);
        if (next == std::wstring::npos) {
            break;
        }
        lines.push_back(pending.substr(pos, next - pos));
        pos = next + 1;
        while (pos < pending.size() && (pending[pos] == L'\r' || pending[pos] == L'\n')) {
            ++pos;
        }
    }
    pending.erase(0, pos);
    return lines;
}

bool StartsWith(const std::wstring& value, const std::wstring& prefix) {
    return value.rfind(prefix, 0) == 0;
}

std::vector<std::wstring> SplitByPipe(const std::wstring& value) {
    std::vector<std::wstring> parts;
    size_t start = 0;
    while (start <= value.size()) {
        size_t pos = value.find(L'|', start);
        if (pos == std::wstring::npos) {
            parts.push_back(value.substr(start));
            break;
        }
        parts.push_back(value.substr(start, pos - start));
        start = pos + 1;
    }
    return parts;
}

std::wstring ExtractSavedPath(const std::wstring& text, const std::wstring& fallbackDir) {
    std::wstringstream stream(text);
    std::wstring line;
    std::wstring path;
    while (std::getline(stream, line)) {
        line = Trim(line);
        const std::wstring destination = L"[download] Destination:";
        size_t destinationPos = line.find(destination);
        if (destinationPos != std::wstring::npos) {
            path = Trim(line.substr(destinationPos + destination.size()));
        }

        const std::wstring merger = L"[Merger] Merging formats into ";
        size_t mergerPos = line.find(merger);
        if (mergerPos != std::wstring::npos) {
            path = Trim(line.substr(mergerPos + merger.size()));
            if (path.size() >= 2 && path.front() == L'"' && path.back() == L'"') {
                path = path.substr(1, path.size() - 2);
            }
        }
    }
    return path.empty() ? fallbackDir : path;
}

unsigned long long ParseDisplaySizeBytes(const std::wstring& text) {
    std::wstring value = Trim(text);
    if (value.empty() || value == L"-") {
        return 0;
    }
    wchar_t* end = nullptr;
    double number = wcstod(value.c_str(), &end);
    if (end == value.c_str() || number <= 0) {
        return 0;
    }
    std::wstring unit = Trim(end ? std::wstring(end) : L"");
    std::transform(unit.begin(), unit.end(), unit.begin(), [](wchar_t c) {
        return static_cast<wchar_t>(towupper(c));
    });
    double multiplier = 1.0;
    if (unit.find(L"KB") != std::wstring::npos || unit.find(L"KIB") != std::wstring::npos) multiplier = 1024.0;
    else if (unit.find(L"MB") != std::wstring::npos || unit.find(L"MIB") != std::wstring::npos) multiplier = 1024.0 * 1024.0;
    else if (unit.find(L"GB") != std::wstring::npos || unit.find(L"GIB") != std::wstring::npos) multiplier = 1024.0 * 1024.0 * 1024.0;
    else if (unit.find(L"TB") != std::wstring::npos || unit.find(L"TIB") != std::wstring::npos) multiplier = 1024.0 * 1024.0 * 1024.0 * 1024.0;
    return static_cast<unsigned long long>(number * multiplier);
}

unsigned long long GetExistingFileSize(const std::wstring& path) {
    WIN32_FILE_ATTRIBUTE_DATA data{};
    if (!GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &data)) {
        return 0;
    }
    ULARGE_INTEGER size{};
    size.HighPart = data.nFileSizeHigh;
    size.LowPart = data.nFileSizeLow;
    return size.QuadPart;
}

std::wstring FindNewestPartFile(const std::wstring& dir) {
    WIN32_FIND_DATAW data{};
    HANDLE find = FindFirstFileW((dir + L"\\*.part").c_str(), &data);
    if (find == INVALID_HANDLE_VALUE) {
        return {};
    }
    std::wstring newest;
    FILETIME newestTime{};
    do {
        if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            continue;
        }
        if (newest.empty() || CompareFileTime(&data.ftLastWriteTime, &newestTime) > 0) {
            newestTime = data.ftLastWriteTime;
            newest = dir + L"\\" + data.cFileName;
        }
    } while (FindNextFileW(find, &data));
    FindClose(find);
    return newest;
}

unsigned long long GetDownloadTempSize(const std::wstring& destinationPath, const std::wstring& downloadsDir) {
    if (!destinationPath.empty()) {
        unsigned long long partSize = GetExistingFileSize(destinationPath + L".part");
        if (partSize > 0) return partSize;
        unsigned long long fileSize = GetExistingFileSize(destinationPath);
        if (fileSize > 0) return fileSize;
    }
    std::wstring newestPart = FindNewestPartFile(downloadsDir);
    return newestPart.empty() ? 0 : GetExistingFileSize(newestPart);
}

std::wstring FormatSpeedBytes(double bytesPerSecond) {
    if (bytesPerSecond <= 0) {
        return L"-";
    }
    const wchar_t* units[] = { L"B/s", L"KiB/s", L"MiB/s", L"GiB/s" };
    int unit = 0;
    while (bytesPerSecond >= 1024.0 && unit < 3) {
        bytesPerSecond /= 1024.0;
        ++unit;
    }
    std::wstringstream ss;
    ss.setf(std::ios::fixed);
    ss.precision(unit == 0 ? 0 : 2);
    ss << bytesPerSecond << units[unit];
    return ss.str();
}

std::wstring ExtractDestinationPath(const std::wstring& line) {
    const std::wstring destination = L"[download] Destination:";
    size_t pos = line.find(destination);
    if (pos == std::wstring::npos) {
        return {};
    }
    return Trim(line.substr(pos + destination.size()));
}

struct DownloadProgressState {
    std::mutex mutex;
    std::wstring destinationPath;
    std::atomic_bool done = false;
};

void MonitorDownloadProgress(HWND hwnd, DownloadProgressState* state, std::wstring downloadsDir, unsigned long long totalBytes) {
    unsigned long long lastBytes = 0;
    ULONGLONG lastTick = GetTickCount64();
    while (!state->done.load()) {
        Sleep(1000);
        std::wstring currentDestination;
        {
            std::lock_guard<std::mutex> lock(state->mutex);
            currentDestination = state->destinationPath;
        }
        unsigned long long currentBytes = GetDownloadTempSize(currentDestination, downloadsDir);
        ULONGLONG now = GetTickCount64();
        double seconds = (now > lastTick) ? (now - lastTick) / 1000.0 : 1.0;
        double speed = currentBytes >= lastBytes ? (currentBytes - lastBytes) / seconds : 0.0;
        lastBytes = currentBytes;
        lastTick = now;
        if (currentBytes == 0 && totalBytes == 0) {
            continue;
        }
        std::wstringstream percent;
        if (totalBytes > 0) {
            double pct = (std::min)(99.9, currentBytes * 100.0 / static_cast<double>(totalBytes));
            percent.setf(std::ios::fixed);
            percent.precision(1);
            percent << pct << L"%";
        } else {
            percent << L"-";
        }
        PostProgressLog(hwnd, L"下载进度：" + percent.str() + L"  速度：" + FormatSpeedBytes(speed) + L"  剩余：-");
    }
}

std::wstring GetCookieArgs() {
    if (g_cookieFileEdit) {
        std::wstring cookieFile = GetWindowTextString(g_cookieFileEdit);
        WriteSetting(L"cookie_file", cookieFile);
        if (!cookieFile.empty()) {
            return L" --cookies " + QuoteArg(cookieFile);
        }
    }
    return {};
}

std::wstring GetCookieFilePath() {
    return g_cookieFileEdit ? GetWindowTextString(g_cookieFileEdit) : L"";
}

bool CookieFileHasName(const std::wstring& cookieFile, const std::string& name) {
    if (cookieFile.empty()) {
        return false;
    }
    std::ifstream input(cookieFile.c_str());
    if (!input) {
        return false;
    }

    std::string line;
    while (std::getline(input, line)) {
        if (line.empty() || line[0] == '#') {
            continue;
        }
        std::vector<std::string> parts;
        std::stringstream ss(line);
        std::string part;
        while (std::getline(ss, part, '\t')) {
            parts.push_back(part);
        }
        if (parts.size() >= 6 && parts[5] == name) {
            return true;
        }
    }
    return false;
}

bool LooksLikeLoggedInYoutubeCookieFile(const std::wstring& cookieFile) {
    return CookieFileHasName(cookieFile, "LOGIN_INFO") ||
        CookieFileHasName(cookieFile, "SID") ||
        CookieFileHasName(cookieFile, "__Secure-1PSID") ||
        CookieFileHasName(cookieFile, "__Secure-3PSID");
}

std::wstring GetExtraArgs() {
    if (!g_extraArgsEdit) {
        return {};
    }
    std::wstring args = GetWindowTextString(g_extraArgsEdit);
    WriteSetting(L"extra_args", args);
    return args.empty() ? L"" : L" " + args;
}

std::wstring GetCompatArgs() {
    return L" --proxy= --force-ipv4 --js-runtimes deno --impersonate chrome --socket-timeout 60 --retries 10 --extractor-retries 10";
}

std::wstring GetExecutableDirectory() {
    wchar_t path[MAX_PATH]{};
    GetModuleFileNameW(nullptr, path, MAX_PATH);
    std::wstring value(path);
    size_t slash = value.find_last_of(L"\\/");
    return slash == std::wstring::npos ? L"." : value.substr(0, slash);
}

bool FileExists(const std::wstring& path) {
    DWORD attrs = GetFileAttributesW(path.c_str());
    return attrs != INVALID_FILE_ATTRIBUTES && !(attrs & FILE_ATTRIBUTE_DIRECTORY);
}

std::wstring GetAppDataDirectory() {
    PWSTR localAppData = nullptr;
    std::wstring base = GetExecutableDirectory();
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &localAppData))) {
        base = std::wstring(localAppData) + L"\\YouTubeDlpDownloader";
        CoTaskMemFree(localAppData);
    }
    CreateDirectoryW(base.c_str(), nullptr);
    return base;
}

std::wstring GetLocalYtDlpPath() {
    return GetAppDataDirectory() + L"\\yt-dlp.exe";
}

std::wstring GetSettingsPath() {
    return GetAppDataDirectory() + L"\\settings.ini";
}

std::wstring ReadSetting(const wchar_t* key) {
    wchar_t buffer[MAX_PATH]{};
    GetPrivateProfileStringW(L"settings", key, L"", buffer, MAX_PATH, GetSettingsPath().c_str());
    return buffer;
}

void WriteSetting(const wchar_t* key, const std::wstring& value) {
    WritePrivateProfileStringW(L"settings", key, value.c_str(), GetSettingsPath().c_str());
}

std::wstring SearchPathForExecutable(const std::wstring& name) {
    wchar_t found[MAX_PATH]{};
    DWORD length = SearchPathW(nullptr, name.c_str(), nullptr, MAX_PATH, found, nullptr);
    if (length > 0 && length < MAX_PATH) {
        return found;
    }
    return {};
}

std::wstring ResolveYtDlpPath(const std::wstring& value) {
    if (value.empty()) {
        return {};
    }
    if (value.find_first_of(L"\\/") != std::wstring::npos || value.find(L":") != std::wstring::npos) {
        return FileExists(value) ? value : L"";
    }
    return SearchPathForExecutable(value);
}

std::wstring DefaultYtDlpPath() {
    if (g_ytDlpService) {
        return g_ytDlpService->YtDlpPath();
    }
    std::wstring local = GetExecutableDirectory() + L"\\yt-dlp.exe";
    if (FileExists(local)) {
        return local;
    }
    std::wstring userLocal = GetLocalYtDlpPath();
    if (FileExists(userLocal)) {
        return userLocal;
    }
    std::wstring pathValue = SearchPathForExecutable(L"yt-dlp.exe");
    return pathValue.empty() ? userLocal : pathValue;
}

std::wstring DefaultDownloadsPath() {
    PWSTR known = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_Downloads, 0, nullptr, &known))) {
        std::wstring result(known);
        CoTaskMemFree(known);
        return result;
    }
    return GetExecutableDirectory();
}

bool RunProcessCapture(const std::wstring& commandLine, std::wstring& output, DWORD& exitCode) {
    SECURITY_ATTRIBUTES sa{};
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;

    HANDLE readPipe = nullptr;
    HANDLE writePipe = nullptr;
    if (!CreatePipe(&readPipe, &writePipe, &sa, 0)) {
        output = L"无法创建进程管道。";
        return false;
    }
    SetHandleInformation(readPipe, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;
    si.hStdOutput = writePipe;
    si.hStdError = writePipe;

    PROCESS_INFORMATION pi{};
    std::wstring mutableCommand = commandLine;
    BOOL ok = CreateProcessW(
        nullptr,
        mutableCommand.data(),
        nullptr,
        nullptr,
        TRUE,
        CREATE_NO_WINDOW,
        nullptr,
        nullptr,
        &si,
        &pi);

    CloseHandle(writePipe);
    if (!ok) {
        CloseHandle(readPipe);
        output = L"启动失败，请检查 yt-dlp.exe 路径是否正确。";
        return false;
    }

    std::string bytes;
    char buffer[4096];
    DWORD read = 0;
    while (ReadFile(readPipe, buffer, sizeof(buffer), &read, nullptr) && read > 0) {
        bytes.append(buffer, buffer + read);
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    CloseHandle(readPipe);

    output = Utf8ToWide(bytes);
    return true;
}

std::wstring JsonString(const JsonValue& object, const wchar_t* key) {
    const JsonValue* value = object.get(key);
    if (!value) {
        return {};
    }
    if (value->type == JsonValue::Type::String) {
        return value->stringValue;
    }
    if (value->type == JsonValue::Type::Number) {
        std::wstringstream ss;
        ss << static_cast<long long>(value->numberValue);
        return ss.str();
    }
    return {};
}

int JsonInt(const JsonValue& object, const wchar_t* key) {
    const JsonValue* value = object.get(key);
    if (!value) {
        return 0;
    }
    if (value->type == JsonValue::Type::Number) {
        return static_cast<int>(value->numberValue);
    }
    if (value->type == JsonValue::Type::String) {
        return _wtoi(value->stringValue.c_str());
    }
    return 0;
}

std::vector<std::wstring> SplitWhitespace(const std::wstring& text) {
    std::vector<std::wstring> parts;
    std::wstringstream ss(text);
    std::wstring part;
    while (ss >> part) {
        parts.push_back(part);
    }
    return parts;
}

bool ParseResolution(const std::wstring& value, int& width, int& height) {
    size_t x = value.find(L'x');
    if (x == std::wstring::npos) {
        return false;
    }
    std::wstring left = value.substr(0, x);
    std::wstring right = value.substr(x + 1);
    if (left.empty() || right.empty()) {
        return false;
    }
    width = _wtoi(left.c_str());
    height = _wtoi(right.c_str());
    return width > 0 && height > 0;
}

bool ContainsText(const std::wstring& text, const std::wstring& needle) {
    return text.find(needle) != std::wstring::npos;
}

bool IsLikelyFileSize(const std::wstring& token) {
    return ContainsText(token, L"KiB") || ContainsText(token, L"MiB") || ContainsText(token, L"GiB") ||
        ContainsText(token, L"TiB") || ContainsText(token, L"KB") || ContainsText(token, L"MB") ||
        ContainsText(token, L"GB") || ContainsText(token, L"TB");
}

std::wstring ExtractFileSize(const std::vector<std::wstring>& parts) {
    for (size_t i = 0; i < parts.size(); ++i) {
        if (IsLikelyFileSize(parts[i])) {
            if (i > 0 && parts[i - 1] == L"~") {
                return L"~" + parts[i];
            }
            return parts[i];
        }
    }
    return L"-";
}

std::wstring ExtractBitrate(const std::vector<std::wstring>& parts) {
    for (const auto& part : parts) {
        if (part.size() > 1 && part.back() == L'k' && iswdigit(part[0])) {
            return part;
        }
    }
    return L"-";
}

int ResolutionPriority(int height) {
    switch (height) {
    case 2160: return 0;
    case 1440: return 1;
    case 1080: return 2;
    case 720: return 3;
    default: return 1000 - height;
    }
}

std::vector<FormatOption> ParseListFormats(const std::wstring& text) {
    std::vector<FormatOption> result;
    std::wistringstream stream(text);
    std::wstring line;

    while (std::getline(stream, line)) {
        if (line.empty()) {
            continue;
        }

        auto parts = SplitWhitespace(line);
        if (parts.size() < 3) {
            continue;
        }

        int width = 0;
        int height = 0;
        std::wstring resolution;
        size_t resolutionIndex = 0;
        bool foundResolution = false;
        for (size_t i = 2; i < parts.size(); ++i) {
            if (ParseResolution(parts[i], width, height)) {
                resolution = parts[i];
                resolutionIndex = i;
                foundResolution = true;
                break;
            }
        }
        if (!foundResolution) {
            continue;
        }
        if (parts[0] == L"ID" || parts[1] == L"mhtml") {
            continue;
        }
        if (line.find(L"storyboard") != std::wstring::npos || line.find(L"images") != std::wstring::npos ||
            line.find(L"audio only") != std::wstring::npos) {
            continue;
        }

        FormatOption option;
        option.id = parts[0];
        option.ext = parts[1];
        option.height = height;
        option.resolution = resolution;
        size_t fpsIndex = resolutionIndex + 1;
        if (parts.size() > fpsIndex && !parts[fpsIndex].empty() && iswdigit(parts[fpsIndex][0])) {
            option.fps = parts[fpsIndex];
            option.resolution += L" " + option.fps + L"fps";
        }

        option.filesize = ExtractFileSize(parts);
        std::wstring bitrate = ExtractBitrate(parts);
        option.note = (bitrate == L"-" ? L"" : L"鐮佺巼 " + bitrate + L" | ") + line;
        option.vcodec = L"-";
        option.acodec = line.find(L"video only") != std::wstring::npos ? L"none" : L"-";
        result.push_back(std::move(option));
    }

    std::sort(result.begin(), result.end(), [](const FormatOption& a, const FormatOption& b) {
        int ap = ResolutionPriority(a.height);
        int bp = ResolutionPriority(b.height);
        if (ap != bp) {
            return ap < bp;
        }
        if (a.height != b.height) {
            return a.height > b.height;
        }
        if (a.fps != b.fps) {
            return a.fps > b.fps;
        }
        if (a.ext != b.ext) {
            return a.ext < b.ext;
        }
        return a.id < b.id;
    });

    return result;
}

std::vector<FormatOption> ParseFormats(const std::wstring& jsonText, std::wstring& title, std::wstring& error) {
    JsonValue root;
    JsonParser parser(jsonText);
    if (!parser.parse(root) || root.type != JsonValue::Type::Object) {
        error = L"解析 yt-dlp JSON 输出失败。";
        return {};
    }

    title = JsonString(root, L"title");
    const JsonValue* formats = root.get(L"formats");
    if (!formats || formats->type != JsonValue::Type::Array) {
        error = L"yt-dlp 输出中没有 formats 列表。";
        return {};
    }

    std::vector<FormatOption> result;
    for (const JsonValue& item : formats->arrayValue) {
        if (item.type != JsonValue::Type::Object) {
            continue;
        }

        FormatOption option;
        option.id = JsonString(item, L"format_id");
        option.ext = JsonString(item, L"ext");
        option.note = JsonString(item, L"format_note");
        option.vcodec = JsonString(item, L"vcodec");
        option.acodec = JsonString(item, L"acodec");
        option.height = JsonInt(item, L"height");
        int width = JsonInt(item, L"width");
        int fps = JsonInt(item, L"fps");

        if (option.id.empty() || option.height <= 0 || option.vcodec.empty() || option.vcodec == L"none") {
            continue;
        }

        if (width > 0) {
            option.resolution = std::to_wstring(width) + L"x" + std::to_wstring(option.height);
        } else {
            option.resolution = std::to_wstring(option.height) + L"p";
        }
        if (fps > 0) {
            option.fps = std::to_wstring(fps);
            option.resolution += L" " + option.fps + L"fps";
        }
        if (option.note.empty()) {
            option.note = option.acodec == L"none" ? L"仅视频，下载时会自动合并最佳音频" : L"视频+音频";
        }
        result.push_back(std::move(option));
    }

    std::sort(result.begin(), result.end(), [](const FormatOption& a, const FormatOption& b) {
        if (a.height != b.height) {
            return a.height > b.height;
        }
        if (a.fps != b.fps) {
            return a.fps > b.fps;
        }
        if (a.ext != b.ext) {
            return a.ext < b.ext;
        }
        return a.id < b.id;
    });

    if (result.empty()) {
        error = L"没有找到可下载的视频分辨率。";
    }
    return result;
}

void AppendRawLogLine(const std::wstring& line) {
    int length = GetWindowTextLengthW(g_logEdit);
    SendMessageW(g_logEdit, EM_SETSEL, length, length);
    std::wstring text = line + L"\r\n";
    SendMessageW(g_logEdit, EM_REPLACESEL, FALSE, reinterpret_cast<LPARAM>(text.c_str()));
}

void AppendUserLog(const std::wstring& line) {
    g_progressLineStart = -1;
    AppendRawLogLine(line);
}

void AppendDebugLog(const std::wstring& line) {
    if (!IsDetailedLogEnabled()) {
        return;
    }
    AppendRawLogLine(line);
}

void AppendProgressLog(const std::wstring& line) {
    std::wstring text = line + L"\r\n";
    if (g_progressLineStart >= 0) {
        int length = GetWindowTextLengthW(g_logEdit);
        SendMessageW(g_logEdit, EM_SETSEL, g_progressLineStart, length);
        SendMessageW(g_logEdit, EM_REPLACESEL, FALSE, reinterpret_cast<LPARAM>(text.c_str()));
        return;
    }
    g_progressLineStart = GetWindowTextLengthW(g_logEdit);
    SendMessageW(g_logEdit, EM_SETSEL, g_progressLineStart, g_progressLineStart);
    SendMessageW(g_logEdit, EM_REPLACESEL, FALSE, reinterpret_cast<LPARAM>(text.c_str()));
}

void AppendLog(const std::wstring& line) {
    AppendUserLog(line);
}

void SetBusy(bool busy) {
    EnableWindow(g_fetchButton, !busy);
    EnableWindow(g_downloadButton, !busy && ListView_GetSelectedCount(g_formatsList) > 0);
    EnableWindow(GetDlgItem(GetParent(g_fetchButton), IDC_DOWNLOAD_YTDLP), !busy);
    EnableWindow(GetDlgItem(GetParent(g_fetchButton), IDC_BROWSE_YTDLP), !busy);
    EnableWindow(g_cookieCheck, !busy);
    EnableWindow(g_cookieBrowser, !busy);
    EnableWindow(g_cookieFileEdit, !busy);
    EnableWindow(g_extraArgsEdit, !busy);
    EnableWindow(GetDlgItem(GetParent(g_fetchButton), IDC_BROWSE_COOKIE_FILE), !busy);
    EnableWindow(g_proxyDirect, !busy);
    EnableWindow(g_proxySystem, !busy);
    EnableWindow(g_proxyCustom, !busy);
    EnableWindow(g_proxyUrlEdit, !busy);
}

void ResizeControls(HWND hwnd) {
    RECT rc{};
    GetClientRect(hwnd, &rc);
    const int margin = 12;
    const int labelW = 80;
    const int buttonW = 86;
    const int updateButtonW = 96;
    const int rowH = 26;
    const int gap = 8;
    int width = rc.right - rc.left;
    int y = margin;
    int editX = margin + labelW;
    int singleButtonEditW = width - editX - buttonW - margin - gap;
    int twoButtonEditW = width - editX - buttonW - updateButtonW - margin - gap * 2;

    MoveWindow(GetDlgItem(hwnd, 2001), margin, y + 4, labelW, 20, TRUE);
    MoveWindow(g_urlEdit, editX, y, width - editX - margin, rowH, TRUE);
    y += rowH + gap;

    MoveWindow(GetDlgItem(hwnd, 2002), margin, y + 4, labelW, 20, TRUE);
    MoveWindow(g_ytdlpEdit, editX, y, twoButtonEditW, rowH, TRUE);
    MoveWindow(GetDlgItem(hwnd, IDC_BROWSE_YTDLP), editX + twoButtonEditW + gap, y, buttonW, rowH, TRUE);
    MoveWindow(GetDlgItem(hwnd, IDC_DOWNLOAD_YTDLP), editX + twoButtonEditW + gap + buttonW + gap, y, updateButtonW, rowH, TRUE);
    y += rowH + gap;

    MoveWindow(GetDlgItem(hwnd, 2003), margin, y + 4, labelW, 20, TRUE);
    MoveWindow(g_outputEdit, editX, y, singleButtonEditW, rowH, TRUE);
    MoveWindow(GetDlgItem(hwnd, IDC_BROWSE_OUTPUT), editX + singleButtonEditW + gap, y, buttonW, rowH, TRUE);
    y += rowH + gap;

    MoveWindow(GetDlgItem(hwnd, 2005), margin, y + 4, labelW, 20, TRUE);
    MoveWindow(g_cookieFileEdit, editX, y, singleButtonEditW, rowH, TRUE);
    MoveWindow(GetDlgItem(hwnd, IDC_BROWSE_COOKIE_FILE), editX + singleButtonEditW + gap, y, buttonW, rowH, TRUE);
    y += rowH + gap;

    MoveWindow(GetDlgItem(hwnd, 2007), margin, y + 4, labelW, 20, TRUE);
    MoveWindow(g_proxyDirect, editX, y, 68, rowH, TRUE);
    MoveWindow(g_proxySystem, editX + 76, y, 96, rowH, TRUE);
    MoveWindow(g_proxyCustom, editX + 180, y, 96, rowH, TRUE);
    MoveWindow(g_proxyUrlEdit, editX + 284, y, width - (editX + 284) - margin, rowH, TRUE);
    y += rowH + gap;

    MoveWindow(g_fetchButton, editX, y, 120, rowH + 4, TRUE);
    MoveWindow(g_downloadButton, editX + 128, y, 120, rowH + 4, TRUE);
    MoveWindow(g_detailedLogCheck, editX + 264, y + 4, 140, rowH, TRUE);
    y += rowH + gap + 8;

    int listH = max(150, (rc.bottom - y - margin) * 55 / 100);
    MoveWindow(g_formatsList, margin, y, width - margin * 2, listH, TRUE);
    y += listH + gap;
    MoveWindow(g_logEdit, margin, y, width - margin * 2, rc.bottom - y - margin, TRUE);
}

void InsertColumn(int index, int width, const wchar_t* title) {
    LVCOLUMNW col{};
    col.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_SUBITEM;
    col.pszText = const_cast<LPWSTR>(title);
    col.cx = width;
    col.iSubItem = index;
    ListView_InsertColumn(g_formatsList, index, &col);
}

void FillFormatList(const std::vector<FormatOption>& formats) {
    ListView_DeleteAllItems(g_formatsList);
    for (size_t i = 0; i < formats.size(); ++i) {
        const auto& f = formats[i];
        LVITEMW item{};
        item.mask = LVIF_TEXT;
        item.iItem = static_cast<int>(i);
        item.pszText = const_cast<LPWSTR>(f.id.c_str());
        ListView_InsertItem(g_formatsList, &item);
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 1, const_cast<LPWSTR>(f.ext.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 2, const_cast<LPWSTR>(f.resolution.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 3, const_cast<LPWSTR>(f.width.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 4, const_cast<LPWSTR>(f.heightText.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 5, const_cast<LPWSTR>(f.fps.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 6, const_cast<LPWSTR>(f.vcodec.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 7, const_cast<LPWSTR>(f.acodec.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 8, const_cast<LPWSTR>(f.filesize.c_str()));
        ListView_SetItemText(g_formatsList, static_cast<int>(i), 9, const_cast<LPWSTR>(f.tbr.c_str()));
    }
    if (!formats.empty()) {
        ListView_SetItemState(g_formatsList, 0, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
    }
    EnableWindow(g_downloadButton, !formats.empty());
}

bool BrowseForExe(HWND owner, std::wstring& path) {
    OPENFILENAMEW ofn{};
    wchar_t file[MAX_PATH]{};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = owner;
    ofn.lpstrFilter = L"yt-dlp.exe\0yt-dlp.exe\0可执行文件\0*.exe\0所有文件\0*.*\0";
    ofn.lpstrFile = file;
    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
    if (!GetOpenFileNameW(&ofn)) {
        return false;
    }
    path = file;
    return true;
}

bool BrowseForCookieFile(HWND owner, std::wstring& path) {
    OPENFILENAMEW ofn{};
    wchar_t file[MAX_PATH]{};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = owner;
    ofn.lpstrFilter = L"Cookie files\0*.txt;*.cookies\0All files\0*.*\0";
    ofn.lpstrFile = file;
    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
    if (!GetOpenFileNameW(&ofn)) {
        return false;
    }
    path = file;
    return true;
}

bool BrowseForFolder(HWND owner, std::wstring& path) {
    BROWSEINFOW bi{};
    bi.hwndOwner = owner;
    bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
    bi.lpszTitle = L"选择下载保存目录";
    PIDLIST_ABSOLUTE pidl = SHBrowseForFolderW(&bi);
    if (!pidl) {
        return false;
    }
    wchar_t buffer[MAX_PATH]{};
    bool ok = SHGetPathFromIDListW(pidl, buffer) == TRUE;
    CoTaskMemFree(pidl);
    if (ok) {
        path = buffer;
    }
    return ok;
}

void DownloadYtDlp(HWND hwnd) {
    if (!g_ytDlpService) {
        return;
    }
    if (!FileExists(g_ytDlpService->YtDlpPath())) {
        MessageBoxW(hwnd, L"缺少 tools\\yt-dlp.exe，无法执行更新。", L"缺少 yt-dlp", MB_ICONWARNING);
        return;
    }
    SetBusy(true);
    AppendUserLog(L"正在更新 yt-dlp...");

    std::thread([hwnd] {
        ProcessResult result = g_ytDlpService->UpdateYtDlpAsync([hwnd](const std::wstring& chunk) {
            PostDebugLog(hwnd, chunk);
        });
        if (result.exitCode == 0) {
            PostUserLog(hwnd, L"yt-dlp 更新完成。");
        } else {
            PostUserLog(hwnd, g_ytDlpService->FriendlyError(result.combinedText));
            if (!result.combinedText.empty()) {
                PostDebugLog(hwnd, result.combinedText);
            }
        }
        PostMessageW(hwnd, WM_APP_WORK_DONE, 0, 0);
    }).detach();
}

std::wstring BuildListFormatsCommand(
    const std::wstring& ytdlp,
    const std::wstring& cookieArgs,
    const std::wstring& url) {
    std::wstring command = QuoteArg(ytdlp)
        + L" --ignore-config"
        + GetCompatArgs()
        + cookieArgs
        + L" --no-warnings --no-playlist";
    command += L" -F " + QuoteArg(url);
    return command;
}

void FetchFormats(HWND hwnd) {
    std::wstring url = GetWindowTextString(g_urlEdit);
    if (url.empty()) {
        MessageBoxW(hwnd, L"请先填写视频链接。", L"缺少信息", MB_ICONWARNING);
        return;
    }
    if (!g_ytDlpService) {
        MessageBoxW(hwnd, L"YtDlpService 未初始化。", L"错误", MB_ICONERROR);
        return;
    }

    ApplyProxyOptions();
    ToolCheckResult check = g_ytDlpService->CheckTools();
    if (!check.ok) {
        for (const auto& error : check.errors) {
            AppendUserLog(error);
        }
        MessageBoxW(hwnd, L"便携工具链不完整，请查看日志。", L"缺少工具", MB_ICONWARNING);
        return;
    }

    SetBusy(true);
    ListView_DeleteAllItems(g_formatsList);
    AppendUserLog(L"正在连接 YouTube...");
    AppendUserLog(L"正在读取视频信息...");
    AppendUserLog(L"正在解析可用格式...");
    AppendDebugLog(L"yt-dlp.exe: " + g_ytDlpService->YtDlpPath());
    AppendDebugLog(L"DenoPath: " + g_ytDlpService->DenoPath());
    AppendDebugLog(L"FfmpegDir: " + g_ytDlpService->FfmpegDir());
    AppendDebugLog(L"CookiesPath: " + g_ytDlpService->CookiesPath());
    AppendDebugLog(L"ProxyMode: " + ProxyModeName(g_ytDlpService->GetProxyMode()));
    AppendDebugLog(L"ProxyUrl: " + g_ytDlpService->ProxyUrl());
    auto debugArgs = g_ytDlpService->BuildGetFormatsArgs(url);
    AppendDebugLog(L"完整 ArgumentList:");
    for (const auto& arg : debugArgs) {
        AppendDebugLog(L"  " + arg);
    }

    std::thread([hwnd, url] {
        std::vector<YtDlpFormat> serviceFormats;
        ProcessResult result = g_ytDlpService->GetFormatsAsync(url, serviceFormats);
        if (result.exitCode != 0) {
            std::wstring combined = result.combinedText.empty() ? result.stdoutText + L"\r\n" + result.stderrText : result.combinedText;
            PostUserLog(hwnd, g_ytDlpService->FriendlyError(combined));
            if (!combined.empty()) {
                PostDebugLog(hwnd, combined);
            }
            PostMessageW(hwnd, WM_APP_WORK_DONE, 0, 0);
            return;
        }

        if (!result.stdoutText.empty()) {
            PostDebugLog(hwnd, result.stdoutText);
        }
        if (!result.stderrText.empty()) {
            PostDebugLog(hwnd, result.stderrText);
        }

        auto formats = std::make_unique<std::vector<FormatOption>>();
        formats->reserve(serviceFormats.size());
        for (const auto& sf : serviceFormats) {
            FormatOption f;
            f.id = sf.id;
            f.ext = sf.ext;
            f.resolution = sf.resolution;
            f.width = sf.width;
            f.heightText = sf.height;
            f.filesize = sf.filesize;
            f.note = L"";
            f.fps = sf.fps;
            f.vcodec = sf.vcodec;
            f.acodec = sf.videoOnly ? L"video only" : sf.acodec;
            f.tbr = sf.tbr;
            f.height = _wtoi(sf.height.c_str());
            formats->push_back(std::move(f));
        }

        if (formats->empty()) {
            PostUserLog(hwnd, L"没有找到可下载的视频格式。");
            PostMessageW(hwnd, WM_APP_WORK_DONE, 0, 0);
            return;
        }

        PostUserLog(hwnd, L"已找到 " + std::to_wstring(formats->size()) + L" 个视频格式。");
        PostMessageW(hwnd, WM_APP_FORMATS_READY, 0, reinterpret_cast<LPARAM>(formats.release()));
    }).detach();
}
void DownloadSelected(HWND hwnd) {
    int selected = ListView_GetNextItem(g_formatsList, -1, LVNI_SELECTED);
    if (selected < 0 || selected >= static_cast<int>(g_formats.size())) {
        MessageBoxW(hwnd, L"请先选择一个分辨率。", L"未选择格式", MB_ICONWARNING);
        return;
    }

    std::wstring url = GetWindowTextString(g_urlEdit);
    if (url.empty()) {
        MessageBoxW(hwnd, L"请先填写视频链接。", L"缺少信息", MB_ICONWARNING);
        return;
    }
    if (!g_ytDlpService) {
        MessageBoxW(hwnd, L"YtDlpService 未初始化。", L"错误", MB_ICONERROR);
        return;
    }

    ApplyProxyOptions();
    ToolCheckResult check = g_ytDlpService->CheckTools();
    if (!check.ok) {
        for (const auto& error : check.errors) {
            AppendUserLog(error);
        }
        MessageBoxW(hwnd, L"便携工具链不完整，请查看日志。", L"缺少工具", MB_ICONWARNING);
        return;
    }

    FormatOption format = g_formats[selected];
    SetBusy(true);
    AppendUserLog(L"开始下载：" + format.resolution + (format.fps.empty() ? L"" : L" " + format.fps + L"fps"));
    AppendDebugLog(L"format_id=" + format.id + L" 保存目录=" + g_ytDlpService->DownloadsDir());

    std::thread([hwnd, url, format] {
        DownloadSelection selection;
        selection.formatId = format.id;
        selection.ext = format.ext;
        selection.vcodec = format.vcodec;

        std::wstring pending;
        ULONGLONG lastTemplateProgressTick = 0;
        bool mergeLogged = false;
        DownloadProgressState progressState;
        unsigned long long totalBytes = ParseDisplaySizeBytes(format.filesize);
        std::wstring downloadsDir = g_ytDlpService->DownloadsDir();

        std::thread monitorThread(MonitorDownloadProgress, hwnd, &progressState, downloadsDir, totalBytes);

        ProcessResult result = g_ytDlpService->DownloadAsync(url, selection, [hwnd, &pending, &lastTemplateProgressTick, &mergeLogged, &progressState](const std::wstring& chunk) {
            PostDebugLog(hwnd, chunk);
            for (const auto& rawLine : SplitTextLines(pending, chunk)) {
                std::wstring line = Trim(rawLine);
                if (line.empty()) {
                    continue;
                }
                std::wstring destination = ExtractDestinationPath(line);
                if (!destination.empty()) {
                    std::lock_guard<std::mutex> lock(progressState.mutex);
                    progressState.destinationPath = destination;
                }
                if (StartsWith(line, L"download:")) {
                    auto parts = SplitByPipe(line.substr(9));
                    if (parts.size() >= 3) {
                        ULONGLONG now = GetTickCount64();
                        if (now - lastTemplateProgressTick >= 1000 || lastTemplateProgressTick == 0) {
                            lastTemplateProgressTick = now;
                            PostProgressLog(hwnd, L"下载进度：" + Trim(parts[0]) + L"  速度：" + Trim(parts[1]) + L"  剩余：" + Trim(parts[2]));
                        }
                    }
                } else if (!mergeLogged && (ContainsText(line, L"[Merger]") || ContainsText(line, L"Merging formats"))) {
                    mergeLogged = true;
                    PostUserLog(hwnd, L"正在合并音视频...");
                }
            }
        });

        progressState.done.store(true);
        if (monitorThread.joinable()) {
            monitorThread.join();
        }

        if (result.exitCode == 0) {
            PostProgressLog(hwnd, L"下载进度：100.0%  速度：-  剩余：00:00");
            PostUserLog(hwnd, L"下载完成：" + ExtractSavedPath(result.combinedText, g_ytDlpService->DownloadsDir()));
        } else {
            PostUserLog(hwnd, g_ytDlpService->FriendlyError(result.combinedText));
            if (!result.combinedText.empty()) {
                PostDebugLog(hwnd, result.combinedText);
            }
        }
        PostMessageW(hwnd, WM_APP_WORK_DONE, 0, 0);
    }).detach();
}
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        g_ytDlpService = std::make_unique<YtDlpService>(GetExecutableDirectoryPortable());
        INITCOMMONCONTROLSEX icc{ sizeof(icc), ICC_LISTVIEW_CLASSES };
        InitCommonControlsEx(&icc);

        HFONT font = reinterpret_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
        CreateWindowW(L"STATIC", L"视频链接", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2001), nullptr, nullptr);
        CreateWindowW(L"STATIC", L"yt-dlp", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2002), nullptr, nullptr);
        CreateWindowW(L"STATIC", L"保存目录", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2003), nullptr, nullptr);
        CreateWindowW(L"STATIC", L"Cookies", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2004), nullptr, nullptr);
        CreateWindowW(L"STATIC", L"Cookie文件", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2005), nullptr, nullptr);
        CreateWindowW(L"STATIC", L"额外参数", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2006), nullptr, nullptr);
        CreateWindowW(L"STATIC", L"网络模式", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(2007), nullptr, nullptr);

        std::wstring savedCookieFile = g_ytDlpService->CookiesPath();
        std::wstring savedExtraArgs = ReadSetting(L"extra_args");
        if (savedExtraArgs.empty()) {
            savedExtraArgs = L"--proxy= --force-ipv4 --js-runtimes deno --impersonate chrome";
        }
        g_urlEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"", WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_URL), nullptr, nullptr);
        g_ytdlpEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", DefaultYtDlpPath().c_str(), WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_YTDLP), nullptr, nullptr);
        g_outputEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", g_ytDlpService->DownloadsDir().c_str(), WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL | ES_READONLY, 0, 0, 0, 0, hwnd, ControlId(IDC_OUTPUT), nullptr, nullptr);
        g_cookieCheck = CreateWindowW(L"BUTTON", L"使用浏览器 Cookies", WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX, 0, 0, 0, 0, hwnd, ControlId(IDC_COOKIE_CHECK), nullptr, nullptr);
        g_cookieBrowser = CreateWindowW(L"COMBOBOX", L"", WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST | WS_VSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_COOKIE_BROWSER), nullptr, nullptr);
        g_cookieFileEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", savedCookieFile.c_str(), WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_COOKIE_FILE), nullptr, nullptr);
        g_extraArgsEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", savedExtraArgs.c_str(), WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_EXTRA_ARGS), nullptr, nullptr);
        g_proxyDirect = CreateWindowW(L"BUTTON", L"直连", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON | WS_GROUP, 0, 0, 0, 0, hwnd, ControlId(IDC_PROXY_DIRECT), nullptr, nullptr);
        g_proxySystem = CreateWindowW(L"BUTTON", L"系统代理", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON, 0, 0, 0, 0, hwnd, ControlId(IDC_PROXY_SYSTEM), nullptr, nullptr);
        g_proxyCustom = CreateWindowW(L"BUTTON", L"自定义", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON, 0, 0, 0, 0, hwnd, ControlId(IDC_PROXY_CUSTOM), nullptr, nullptr);
        g_proxyUrlEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"http://127.0.0.1:7897", WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_PROXY_URL), nullptr, nullptr);
        SendMessageW(g_proxyCustom, BM_SETCHECK, BST_CHECKED, 0);
        CreateWindowW(L"BUTTON", L"浏览...", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(IDC_BROWSE_COOKIE_FILE), nullptr, nullptr);
        CreateWindowW(L"BUTTON", L"浏览...", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(IDC_BROWSE_YTDLP), nullptr, nullptr);
        CreateWindowW(L"BUTTON", L"更新yt-dlp", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(IDC_DOWNLOAD_YTDLP), nullptr, nullptr);
        CreateWindowW(L"BUTTON", L"浏览...", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(IDC_BROWSE_OUTPUT), nullptr, nullptr);
        g_fetchButton = CreateWindowW(L"BUTTON", L"获取分辨率", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, hwnd, ControlId(IDC_FETCH), nullptr, nullptr);
        g_downloadButton = CreateWindowW(L"BUTTON", L"下载选中项", WS_CHILD | WS_VISIBLE | WS_DISABLED, 0, 0, 0, 0, hwnd, ControlId(IDC_DOWNLOAD), nullptr, nullptr);
        g_detailedLogCheck = CreateWindowW(L"BUTTON", L"显示详细日志", WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX, 0, 0, 0, 0, hwnd, ControlId(IDC_DETAILED_LOG), nullptr, nullptr);
        g_formatsList = CreateWindowExW(WS_EX_CLIENTEDGE, WC_LISTVIEWW, L"", WS_CHILD | WS_VISIBLE | LVS_REPORT | LVS_SINGLESEL | LVS_SHOWSELALWAYS, 0, 0, 0, 0, hwnd, ControlId(IDC_FORMATS), nullptr, nullptr);
        g_logEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"", WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY | WS_VSCROLL, 0, 0, 0, 0, hwnd, ControlId(IDC_LOG), nullptr, nullptr);

        HWND controls[] = {
            GetDlgItem(hwnd, 2001), GetDlgItem(hwnd, 2002), GetDlgItem(hwnd, 2003), GetDlgItem(hwnd, 2004), GetDlgItem(hwnd, 2005), GetDlgItem(hwnd, 2006), GetDlgItem(hwnd, 2007),
            g_urlEdit, g_ytdlpEdit, g_outputEdit, GetDlgItem(hwnd, IDC_BROWSE_YTDLP),
            GetDlgItem(hwnd, IDC_DOWNLOAD_YTDLP), GetDlgItem(hwnd, IDC_BROWSE_OUTPUT), g_fetchButton, g_downloadButton,
            g_cookieCheck, g_cookieBrowser, g_cookieFileEdit, g_extraArgsEdit, g_proxyDirect, g_proxySystem,
            g_proxyCustom, g_proxyUrlEdit, g_detailedLogCheck, GetDlgItem(hwnd, IDC_BROWSE_COOKIE_FILE), g_formatsList, g_logEdit
        };
        for (HWND control : controls) {
            SendMessageW(control, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
        }

        SendMessageW(g_cookieBrowser, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"chrome"));
        SendMessageW(g_cookieBrowser, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"edge"));
        SendMessageW(g_cookieBrowser, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"firefox"));
        SendMessageW(g_cookieBrowser, CB_SETCURSEL, 0, 0);
        ShowWindow(GetDlgItem(hwnd, 2004), SW_HIDE);
        ShowWindow(GetDlgItem(hwnd, 2006), SW_HIDE);
        ShowWindow(g_cookieCheck, SW_HIDE);
        ShowWindow(g_cookieBrowser, SW_HIDE);
        ShowWindow(g_extraArgsEdit, SW_HIDE);
        ApplyProxyOptions();

        ListView_SetExtendedListViewStyle(g_formatsList, LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES | LVS_EX_DOUBLEBUFFER);
        InsertColumn(0, 80, L"format_id");
        InsertColumn(1, 60, L"ext");
        InsertColumn(2, 120, L"resolution");
        InsertColumn(3, 80, L"width");
        InsertColumn(4, 80, L"height");
        InsertColumn(5, 70, L"fps");
        InsertColumn(6, 170, L"vcodec");
        InsertColumn(7, 110, L"acodec");
        InsertColumn(8, 100, L"size");
        InsertColumn(9, 80, L"tbr");

        AppendLog(L"程序目录：" + g_ytDlpService->AppDir());
        AppendLog(L"下载目录：" + g_ytDlpService->DownloadsDir());
        ToolCheckResult check = g_ytDlpService->CheckTools();
        if (!check.ok) {
            AppendLog(L"便携工具链检查未通过：");
            for (const auto& error : check.errors) {
                AppendLog(error);
            }
        } else {
            AppendLog(L"便携工具链检查通过。");
        }
        AppendLog(L"请填写 YouTube 视频链接，然后点击“获取分辨率”。");
        ResizeControls(hwnd);
        return 0;
    }
    case WM_SIZE:
        ResizeControls(hwnd);
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_BROWSE_YTDLP: {
            std::wstring path;
            if (BrowseForExe(hwnd, path)) {
                SetWindowTextString(g_ytdlpEdit, path);
            }
            return 0;
        }
        case IDC_DOWNLOAD_YTDLP:
            DownloadYtDlp(hwnd);
            return 0;
        case IDC_BROWSE_OUTPUT: {
            std::wstring path;
            if (BrowseForFolder(hwnd, path)) {
                SetWindowTextString(g_outputEdit, path);
            }
            return 0;
        }
        case IDC_BROWSE_COOKIE_FILE: {
            std::wstring path;
            if (BrowseForCookieFile(hwnd, path)) {
                std::wstring error;
                if (g_ytDlpService && g_ytDlpService->ImportCookies(path, error)) {
                    SetWindowTextString(g_cookieFileEdit, g_ytDlpService->CookiesPath());
                    WriteSetting(L"cookie_file", g_ytDlpService->CookiesPath());
                    AppendUserLog(L"已导入 Cookie：" + g_ytDlpService->CookiesPath());
                } else {
                    MessageBoxW(hwnd, error.empty() ? L"Cookie 文件可能无效，请确认这是从 YouTube 登录状态导出的 cookies.txt。" : error.c_str(), L"导入失败", MB_ICONWARNING);
                }
            }
            return 0;
        }
        case IDC_FETCH:
            FetchFormats(hwnd);
            return 0;
        case IDC_DOWNLOAD:
            DownloadSelected(hwnd);
            return 0;
        case IDC_PROXY_DIRECT:
        case IDC_PROXY_SYSTEM:
        case IDC_PROXY_CUSTOM:
            ApplyProxyOptions();
            return 0;
        }
        break;
    case WM_NOTIFY:
        if (reinterpret_cast<NMHDR*>(lParam)->idFrom == IDC_FORMATS) {
            EnableWindow(g_downloadButton, ListView_GetSelectedCount(g_formatsList) > 0);
        }
        break;
    case WM_APP_LOG: {
        std::unique_ptr<std::wstring> text(reinterpret_cast<std::wstring*>(lParam));
        AppendUserLog(*text);
        return 0;
    }
    case WM_APP_DEBUG_LOG: {
        std::unique_ptr<std::wstring> text(reinterpret_cast<std::wstring*>(lParam));
        AppendDebugLog(*text);
        return 0;
    }
    case WM_APP_PROGRESS_LOG: {
        std::unique_ptr<std::wstring> text(reinterpret_cast<std::wstring*>(lParam));
        AppendProgressLog(*text);
        return 0;
    }
    case WM_APP_FORMATS_READY: {
        std::unique_ptr<std::vector<FormatOption>> formats(reinterpret_cast<std::vector<FormatOption>*>(lParam));
        g_formats = std::move(*formats);
        FillFormatList(g_formats);
        SetBusy(false);
        return 0;
    }
    case WM_APP_WORK_DONE:
        if (wParam == 1 && lParam) {
            std::unique_ptr<std::wstring> path(reinterpret_cast<std::wstring*>(lParam));
            SetWindowTextString(g_ytdlpEdit, *path);
        }
        SetBusy(false);
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

} // namespace

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int nCmdShow) {
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE);

    const wchar_t* className = L"YouTubeDlpDownloaderWindow";
    WNDCLASSW wc{};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    wc.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
    wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
    wc.lpszClassName = className;

    if (!RegisterClassW(&wc)) {
        MessageBoxW(nullptr, L"窗口类注册失败。", L"错误", MB_ICONERROR);
        return 1;
    }

    HWND hwnd = CreateWindowExW(
        0,
        className,
        L"YouTube yt-dlp 视频下载器",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        1500,
        1000,
        nullptr,
        nullptr,
        hInstance,
        nullptr);

    if (!hwnd) {
        MessageBoxW(nullptr, L"创建窗口失败。", L"错误", MB_ICONERROR);
        return 1;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    MSG msg{};
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return static_cast<int>(msg.wParam);
}

