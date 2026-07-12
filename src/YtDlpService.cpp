#include "YtDlpService.h"

#include <windows.h>
#include <shlobj.h>
#include <shlwapi.h>

#include <algorithm>
#include <cmath>
#include <fstream>
#include <map>
#include <mutex>
#include <sstream>
#include <thread>

#pragma comment(lib, "Shlwapi.lib")

namespace {

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
        skip();
        if (!value(out)) return false;
        skip();
        return pos_ == text_.size();
    }

private:
    const std::wstring& text_;
    size_t pos_ = 0;

    void skip() {
        while (pos_ < text_.size() && iswspace(text_[pos_])) ++pos_;
    }

    bool take(wchar_t c) {
        if (pos_ < text_.size() && text_[pos_] == c) {
            ++pos_;
            return true;
        }
        return false;
    }

    bool literal(const wchar_t* text) {
        size_t len = wcslen(text);
        if (text_.compare(pos_, len, text) != 0) return false;
        pos_ += len;
        return true;
    }

    bool value(JsonValue& out) {
        skip();
        if (pos_ >= text_.size()) return false;
        wchar_t c = text_[pos_];
        if (c == L'{') return object(out);
        if (c == L'[') return array(out);
        if (c == L'"') {
            out.type = JsonValue::Type::String;
            return string(out.stringValue);
        }
        if (c == L't') {
            if (!literal(L"true")) return false;
            out.type = JsonValue::Type::Bool;
            out.boolValue = true;
            return true;
        }
        if (c == L'f') {
            if (!literal(L"false")) return false;
            out.type = JsonValue::Type::Bool;
            out.boolValue = false;
            return true;
        }
        if (c == L'n') {
            if (!literal(L"null")) return false;
            out.type = JsonValue::Type::Null;
            return true;
        }
        if (c == L'-' || iswdigit(c)) {
            out.type = JsonValue::Type::Number;
            return number(out.numberValue);
        }
        return false;
    }

    bool object(JsonValue& out) {
        if (!take(L'{')) return false;
        out.type = JsonValue::Type::Object;
        skip();
        if (take(L'}')) return true;
        while (pos_ < text_.size()) {
            std::wstring key;
            if (!string(key)) return false;
            skip();
            if (!take(L':')) return false;
            JsonValue v;
            if (!value(v)) return false;
            out.objectValue.emplace(std::move(key), std::move(v));
            skip();
            if (take(L'}')) return true;
            if (!take(L',')) return false;
            skip();
        }
        return false;
    }

    bool array(JsonValue& out) {
        if (!take(L'[')) return false;
        out.type = JsonValue::Type::Array;
        skip();
        if (take(L']')) return true;
        while (pos_ < text_.size()) {
            JsonValue v;
            if (!value(v)) return false;
            out.arrayValue.push_back(std::move(v));
            skip();
            if (take(L']')) return true;
            if (!take(L',')) return false;
            skip();
        }
        return false;
    }

    bool string(std::wstring& out) {
        if (!take(L'"')) return false;
        out.clear();
        while (pos_ < text_.size()) {
            wchar_t c = text_[pos_++];
            if (c == L'"') return true;
            if (c != L'\\') {
                out.push_back(c);
                continue;
            }
            if (pos_ >= text_.size()) return false;
            wchar_t e = text_[pos_++];
            switch (e) {
            case L'"': out.push_back(L'"'); break;
            case L'\\': out.push_back(L'\\'); break;
            case L'/': out.push_back(L'/'); break;
            case L'b': out.push_back(L'\b'); break;
            case L'f': out.push_back(L'\f'); break;
            case L'n': out.push_back(L'\n'); break;
            case L'r': out.push_back(L'\r'); break;
            case L't': out.push_back(L'\t'); break;
            case L'u': {
                if (pos_ + 4 > text_.size()) return false;
                std::wstring hex = text_.substr(pos_, 4);
                wchar_t* end = nullptr;
                long code = wcstol(hex.c_str(), &end, 16);
                if (end == hex.c_str() || *end != L'\0') return false;
                out.push_back(static_cast<wchar_t>(code));
                pos_ += 4;
                break;
            }
            default:
                return false;
            }
        }
        return false;
    }

    bool number(double& out) {
        size_t start = pos_;
        if (text_[pos_] == L'-') ++pos_;
        while (pos_ < text_.size() && iswdigit(text_[pos_])) ++pos_;
        if (pos_ < text_.size() && text_[pos_] == L'.') {
            ++pos_;
            while (pos_ < text_.size() && iswdigit(text_[pos_])) ++pos_;
        }
        if (pos_ < text_.size() && (text_[pos_] == L'e' || text_[pos_] == L'E')) {
            ++pos_;
            if (pos_ < text_.size() && (text_[pos_] == L'+' || text_[pos_] == L'-')) ++pos_;
            while (pos_ < text_.size() && iswdigit(text_[pos_])) ++pos_;
        }
        std::wstring n = text_.substr(start, pos_ - start);
        wchar_t* end = nullptr;
        out = wcstod(n.c_str(), &end);
        return end != n.c_str() && *end == L'\0';
    }
};

bool FileExists(const std::wstring& path) {
    DWORD attrs = GetFileAttributesW(path.c_str());
    return attrs != INVALID_FILE_ATTRIBUTES && !(attrs & FILE_ATTRIBUTE_DIRECTORY);
}

unsigned long long FileSizeBytes(const std::wstring& path) {
    WIN32_FILE_ATTRIBUTE_DATA data{};
    if (!GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &data)) {
        return 0;
    }
    ULARGE_INTEGER size{};
    size.HighPart = data.nFileSizeHigh;
    size.LowPart = data.nFileSizeLow;
    return size.QuadPart;
}

std::wstring FullPath(const std::wstring& path) {
    wchar_t buffer[MAX_PATH]{};
    DWORD length = GetFullPathNameW(path.c_str(), MAX_PATH, buffer, nullptr);
    if (length == 0 || length >= MAX_PATH) {
        return path;
    }
    return buffer;
}

bool SamePath(const std::wstring& a, const std::wstring& b) {
    return _wcsicmp(FullPath(a).c_str(), FullPath(b).c_str()) == 0;
}

bool CookieContentLooksValid(const std::wstring& path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) {
        return false;
    }
    std::string content((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
    std::transform(content.begin(), content.end(), content.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return content.find("youtube.com") != std::string::npos || content.find("google.com") != std::string::npos;
}

void EnsureDirectory(const std::wstring& path) {
    SHCreateDirectoryExW(nullptr, path.c_str(), nullptr);
}

std::wstring Utf8ToWide(const std::string& text) {
    if (text.empty()) return {};
    int len = MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
    if (len <= 0) {
        len = MultiByteToWideChar(CP_ACP, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
        std::wstring fallback(len, L'\0');
        MultiByteToWideChar(CP_ACP, 0, text.data(), static_cast<int>(text.size()), fallback.data(), len);
        return fallback;
    }
    std::wstring out(len, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), out.data(), len);
    return out;
}

std::wstring QuoteArg(const std::wstring& arg) {
    std::wstring quoted = L"\"";
    size_t slashCount = 0;
    for (wchar_t c : arg) {
        if (c == L'\\') {
            ++slashCount;
        } else if (c == L'"') {
            quoted.append(slashCount * 2 + 1, L'\\');
            quoted.push_back(c);
            slashCount = 0;
        } else {
            quoted.append(slashCount, L'\\');
            slashCount = 0;
            quoted.push_back(c);
        }
    }
    quoted.append(slashCount * 2, L'\\');
    quoted.push_back(L'"');
    return quoted;
}

std::wstring BuildCommandLine(const std::wstring& exe, const std::vector<std::wstring>& args) {
    std::wstring cmd = QuoteArg(exe);
    for (const auto& arg : args) {
        cmd += L" " + QuoteArg(arg);
    }
    return cmd;
}

std::wstring JsonString(const JsonValue& object, const wchar_t* key) {
    const JsonValue* value = object.get(key);
    if (!value) return {};
    if (value->type == JsonValue::Type::String) return value->stringValue;
    if (value->type == JsonValue::Type::Number) {
        std::wstringstream ss;
        ss << static_cast<long long>(value->numberValue);
        return ss.str();
    }
    return {};
}

int JsonInt(const JsonValue& object, const wchar_t* key) {
    const JsonValue* value = object.get(key);
    if (!value) return 0;
    if (value->type == JsonValue::Type::Number) return static_cast<int>(value->numberValue);
    if (value->type == JsonValue::Type::String) return _wtoi(value->stringValue.c_str());
    return 0;
}

double JsonNumber(const JsonValue& object, const wchar_t* key) {
    const JsonValue* value = object.get(key);
    if (!value) return 0;
    if (value->type == JsonValue::Type::Number) return value->numberValue;
    if (value->type == JsonValue::Type::String) return wcstod(value->stringValue.c_str(), nullptr);
    return 0;
}

std::wstring FormatBytes(double bytes) {
    if (bytes <= 0) return L"-";
    const wchar_t* units[] = { L"B", L"KB", L"MB", L"GB", L"TB" };
    int unit = 0;
    while (bytes >= 1024.0 && unit < 4) {
        bytes /= 1024.0;
        ++unit;
    }
    std::wstringstream ss;
    ss.setf(std::ios::fixed);
    ss.precision(unit == 0 ? 0 : 1);
    ss << bytes << units[unit];
    return ss.str();
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

std::vector<YtDlpFormat> ParseFormatsJson(const std::wstring& json, std::wstring& error) {
    JsonValue root;
    JsonParser parser(json);
    if (!parser.parse(root) || root.type != JsonValue::Type::Object) {
        error = L"解析 yt-dlp JSON 输出失败。";
        return {};
    }

    const JsonValue* formats = root.get(L"formats");
    if (!formats || formats->type != JsonValue::Type::Array) {
        error = L"yt-dlp JSON 中没有 formats 数组。";
        return {};
    }

    std::vector<YtDlpFormat> out;
    for (const JsonValue& item : formats->arrayValue) {
        if (item.type != JsonValue::Type::Object) continue;
        std::wstring vcodec = JsonString(item, L"vcodec");
        int height = JsonInt(item, L"height");
        int width = JsonInt(item, L"width");
        if (height <= 0 || vcodec.empty() || vcodec == L"none") continue;

        YtDlpFormat f;
        f.id = JsonString(item, L"format_id");
        if (f.id.rfind(L"sb", 0) == 0) continue;
        f.ext = JsonString(item, L"ext");
        f.width = width > 0 ? std::to_wstring(width) : L"";
        f.height = std::to_wstring(height);
        f.resolution = width > 0 ? std::to_wstring(width) + L"x" + std::to_wstring(height) : std::to_wstring(height) + L"p";
        int fps = JsonInt(item, L"fps");
        f.fps = fps > 0 ? std::to_wstring(fps) : L"";
        f.vcodec = vcodec;
        f.acodec = JsonString(item, L"acodec");
        f.videoOnly = f.acodec.empty() || f.acodec == L"none";
        double size = JsonNumber(item, L"filesize");
        if (size <= 0) size = JsonNumber(item, L"filesize_approx");
        f.filesize = FormatBytes(size);
        double tbr = JsonNumber(item, L"tbr");
        if (tbr > 0) {
            std::wstringstream ss;
            ss.setf(std::ios::fixed);
            ss.precision(0);
            ss << tbr << L"k";
            f.tbr = ss.str();
        }
        if (!f.id.empty()) out.push_back(std::move(f));
    }

    std::sort(out.begin(), out.end(), [](const YtDlpFormat& a, const YtDlpFormat& b) {
        int ah = _wtoi(a.height.c_str());
        int bh = _wtoi(b.height.c_str());
        int ap = ResolutionPriority(ah);
        int bp = ResolutionPriority(bh);
        if (ap != bp) return ap < bp;
        if (ah != bh) return ah > bh;
        if (a.fps != b.fps) return a.fps > b.fps;
        if (a.ext != b.ext) return a.ext < b.ext;
        return a.id < b.id;
    });
    return out;
}

} // namespace

std::wstring GetExecutableDirectoryPortable() {
    wchar_t path[MAX_PATH]{};
    GetModuleFileNameW(nullptr, path, MAX_PATH);
    std::wstring value(path);
    size_t slash = value.find_last_of(L"\\/");
    return slash == std::wstring::npos ? L"." : value.substr(0, slash);
}

YtDlpService::YtDlpService(std::wstring appDir) : appDir_(std::move(appDir)) {
    ytDlpPath_ = appDir_ + L"\\tools\\yt-dlp.exe";
    denoPath_ = appDir_ + L"\\tools\\deno.exe";
    ffmpegDir_ = appDir_ + L"\\tools\\ffmpeg\\bin";
    cookiesPath_ = appDir_ + L"\\config\\yt_cookies.txt";
    downloadsDir_ = appDir_ + L"\\Downloads";
    EnsureDirectory(appDir_ + L"\\tools");
    EnsureDirectory(appDir_ + L"\\tools\\ffmpeg\\bin");
    EnsureDirectory(appDir_ + L"\\config");
    EnsureDirectory(downloadsDir_);
}
ToolCheckResult YtDlpService::CheckTools() const {
    ToolCheckResult result;
    if (!FileExists(ytDlpPath_)) result.errors.push_back(L"缺少 yt-dlp.exe：" + ytDlpPath_);
    if (!FileExists(denoPath_)) result.errors.push_back(L"缺少 deno.exe：" + denoPath_);
    if (!FileExists(ffmpegDir_ + L"\\ffmpeg.exe")) result.errors.push_back(L"缺少 ffmpeg.exe：" + ffmpegDir_ + L"\\ffmpeg.exe");
    if (!FileExists(ffmpegDir_ + L"\\ffprobe.exe")) result.errors.push_back(L"缺少 ffprobe.exe：" + ffmpegDir_ + L"\\ffprobe.exe");
    if (!FileExists(cookiesPath_)) result.errors.push_back(L"缺少 YouTube cookies 文件，请先导入 cookies：" + cookiesPath_);
    result.ok = result.errors.empty();
    return result;
}

bool YtDlpService::ImportCookies(const std::wstring& sourcePath, std::wstring& error) const {
    EnsureDirectory(appDir_ + L"\\config");
    if (!FileExists(sourcePath)) {
        error = L"选择的 cookies 文件不存在。";
        return false;
    }
    if (!SamePath(sourcePath, cookiesPath_)) {
        if (!CopyFileW(sourcePath.c_str(), cookiesPath_.c_str(), FALSE)) {
            error = L"复制 cookies 到 config\\yt_cookies.txt 失败。";
            return false;
        }
    }
    if (!FileExists(cookiesPath_) || FileSizeBytes(cookiesPath_) <= 1024 || !CookieContentLooksValid(cookiesPath_)) {
        error = L"Cookie 文件可能无效，请确认这是从 YouTube 登录状态导出的 cookies.txt。";
        return false;
    }
    return true;
}
void YtDlpService::SetProxyOptions(ProxyMode mode, std::wstring proxyUrl) {
    proxyMode_ = mode;
    proxyUrl_ = std::move(proxyUrl);
}

std::vector<std::wstring> YtDlpService::CommonArgs() const {
    std::vector<std::wstring> args;
    args.push_back(L"--ignore-config");
    if (proxyMode_ == ProxyMode::Direct) {
        args.push_back(L"--proxy=");
    } else if (proxyMode_ == ProxyMode::Custom) {
        args.push_back(L"--proxy");
        args.push_back(proxyUrl_);
    }
    args.push_back(L"--force-ipv4");
    args.push_back(L"--js-runtimes");
    args.push_back(L"deno:" + denoPath_);
    args.push_back(L"--ffmpeg-location");
    args.push_back(ffmpegDir_);
    args.push_back(L"--cookies");
    args.push_back(cookiesPath_);
    args.push_back(L"--impersonate");
    args.push_back(L"chrome");
    args.push_back(L"--no-playlist");
    args.push_back(L"--socket-timeout");
    args.push_back(L"60");
    return args;
}

ProcessResult YtDlpService::RunTool(const std::vector<std::wstring>& args, std::function<void(const std::wstring&)> onOutput) const {
    ProcessResult result;
    SECURITY_ATTRIBUTES sa{};
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;

    HANDLE outRead = nullptr, outWrite = nullptr;
    HANDLE errRead = nullptr, errWrite = nullptr;
    if (!CreatePipe(&outRead, &outWrite, &sa, 0) || !CreatePipe(&errRead, &errWrite, &sa, 0)) {
        result.stderrText = L"无法创建进程管道。";
        result.combinedText = result.stderrText;
        return result;
    }
    SetHandleInformation(outRead, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(errRead, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;
    si.hStdOutput = outWrite;
    si.hStdError = errWrite;

    PROCESS_INFORMATION pi{};
    std::wstring cmd = BuildCommandLine(ytDlpPath_, args);
    BOOL ok = CreateProcessW(
        ytDlpPath_.c_str(),
        cmd.data(),
        nullptr,
        nullptr,
        TRUE,
        CREATE_NO_WINDOW,
        nullptr,
        appDir_.c_str(),
        &si,
        &pi);
    CloseHandle(outWrite);
    CloseHandle(errWrite);

    if (!ok) {
        CloseHandle(outRead);
        CloseHandle(errRead);
        result.stderrText = L"启动 yt-dlp.exe 失败。";
        result.combinedText = result.stderrText;
        return result;
    }

    std::mutex outputMutex;
    auto reader = [&](HANDLE handle, std::wstring& target) {
        std::string bytes;
        char buffer[4096];
        DWORD read = 0;
        while (ReadFile(handle, buffer, sizeof(buffer), &read, nullptr) && read > 0) {
            bytes.append(buffer, buffer + read);
            std::wstring chunk = Utf8ToWide(std::string(buffer, buffer + read));
            {
                std::lock_guard<std::mutex> lock(outputMutex);
                target += chunk;
                result.combinedText += chunk;
            }
            if (onOutput) onOutput(chunk);
        }
    };

    std::thread stdoutThread([&] { reader(outRead, result.stdoutText); });
    std::thread stderrThread([&] { reader(errRead, result.stderrText); });

    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &result.exitCode);
    stdoutThread.join();
    stderrThread.join();

    CloseHandle(outRead);
    CloseHandle(errRead);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return result;
}

ProcessResult YtDlpService::GetFormatsAsync(const std::wstring& url, std::vector<YtDlpFormat>& formats) const {
    auto args = BuildGetFormatsArgs(url);
    ProcessResult result = RunTool(args);
    if (result.exitCode != 0) return result;
    std::wstring parseError;
    formats = ParseFormatsJson(result.stdoutText, parseError);
    if (!parseError.empty()) {
        result.exitCode = 2;
        result.stderrText = parseError;
        result.combinedText += L"\r\n" + parseError;
    }
    return result;
}

std::vector<std::wstring> YtDlpService::BuildGetFormatsArgs(const std::wstring& url) const {
    auto args = CommonArgs();
    args.push_back(L"-J");
    args.push_back(url);
    return args;
}

ProcessResult YtDlpService::DownloadAsync(
    const std::wstring& url,
    const DownloadSelection& selection,
    std::function<void(const std::wstring&)> onOutput) const {
    auto args = CommonArgs();
    std::wstring selector;
    std::wstring mergeFormat;
    if (selection.best4k) {
        selector = L"bv*[height<=2160]+ba/best";
        mergeFormat = L"mkv";
    } else if (selection.bestMp4 || selection.compatibleMp4) {
        selector = L"137+140";
        mergeFormat = L"mp4";
    } else {
        selector = selection.formatId + L"+ba";
    }

    args.push_back(L"--newline");
    args.push_back(L"--progress-template");
    args.push_back(L"download:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s");
    args.push_back(L"-f");
    args.push_back(selector);
    if (!mergeFormat.empty()) {
        args.push_back(L"--merge-output-format");
        args.push_back(mergeFormat);
    }
    args.push_back(L"-P");
    args.push_back(downloadsDir_);
    args.push_back(url);
    return RunTool(args, onOutput);
}

ProcessResult YtDlpService::UpdateYtDlpAsync(std::function<void(const std::wstring&)> onOutput) const {
    return RunTool({ L"-U" }, onOutput);
}

std::wstring YtDlpService::BuildDebugCommand(const std::vector<std::wstring>& args) const {
    return BuildCommandLine(ytDlpPath_, args);
}

std::wstring YtDlpService::FriendlyError(const std::wstring& text) const {
    if (text.find(L"Sign in to confirm you") != std::wstring::npos && text.find(L"bot") != std::wstring::npos) {
        return L"YouTube 要求登录验证。请重新导入有效的 cookies.txt。";
    }
    if (text.find(L"Sign in to confirm your age") != std::wstring::npos) {
        return L"该视频需要年龄验证。请确认浏览器中同一账号可以播放该视频，然后重新导出 cookies。";
    }
    if (text.find(L"Failed to connect") != std::wstring::npos ||
        text.find(L"Connection timed out") != std::wstring::npos ||
        text.find(L"curl: (28)") != std::wstring::npos) {
        return L"连接 YouTube 超时。请检查代理是否开启，或切换网络模式。";
    }
    if (text.find(L"No supported JavaScript runtime") != std::wstring::npos) {
        return L"缺少 Deno，或 Deno 路径错误。请确认 tools\\deno.exe 存在。";
    }
    if (text.find(L"ffmpeg") != std::wstring::npos && text.find(L"not found") != std::wstring::npos) {
        return L"缺少 ffmpeg，请确认 tools\\ffmpeg\\bin\\ffmpeg.exe 存在。";
    }
    if (text.find(L"Requested format is not available") != std::wstring::npos) {
        return L"所选格式不可用，请重新获取分辨率后再选择。";
    }
    if (text.find(L"Unsupported URL") != std::wstring::npos) {
        return L"链接不支持或格式不正确。";
    }
    if (text.find(L"EOF occurred in violation of protocol") != std::wstring::npos) {
        return L"网络 TLS 连接被中断。请检查杀毒软件 HTTPS 扫描或网络环境。";
    }
    return L"yt-dlp 执行失败，请查看详细日志。";
}
