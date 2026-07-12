#pragma once

#include <windows.h>

#include <functional>
#include <string>
#include <vector>

struct YtDlpFormat {
    std::wstring id;
    std::wstring ext;
    std::wstring resolution;
    std::wstring width;
    std::wstring height;
    std::wstring fps;
    std::wstring vcodec;
    std::wstring acodec;
    std::wstring filesize;
    std::wstring tbr;
    bool videoOnly = false;
};

struct ToolCheckResult {
    bool ok = false;
    std::vector<std::wstring> errors;
};

struct ProcessResult {
    DWORD exitCode = 1;
    std::wstring stdoutText;
    std::wstring stderrText;
    std::wstring combinedText;
};

struct DownloadSelection {
    std::wstring formatId;
    std::wstring ext;
    std::wstring vcodec;
    bool compatibleMp4 = false;
    bool best4k = false;
    bool bestMp4 = false;
};

enum class ProxyMode {
    Direct = 0,
    System = 1,
    Custom = 2
};

class YtDlpService {
public:
    explicit YtDlpService(std::wstring appDir);

    const std::wstring& AppDir() const { return appDir_; }
    const std::wstring& YtDlpPath() const { return ytDlpPath_; }
    const std::wstring& DenoPath() const { return denoPath_; }
    const std::wstring& FfmpegDir() const { return ffmpegDir_; }
    const std::wstring& CookiesPath() const { return cookiesPath_; }
    const std::wstring& DownloadsDir() const { return downloadsDir_; }
    ProxyMode GetProxyMode() const { return proxyMode_; }
    const std::wstring& ProxyUrl() const { return proxyUrl_; }
    void SetProxyOptions(ProxyMode mode, std::wstring proxyUrl);

    ToolCheckResult CheckTools() const;
    bool ImportCookies(const std::wstring& sourcePath, std::wstring& error) const;
    ProcessResult UpdateYtDlpAsync(std::function<void(const std::wstring&)> onOutput = nullptr) const;
    ProcessResult GetFormatsAsync(const std::wstring& url, std::vector<YtDlpFormat>& formats) const;
    ProcessResult DownloadAsync(
        const std::wstring& url,
        const DownloadSelection& selection,
        std::function<void(const std::wstring&)> onOutput = nullptr) const;

    std::wstring BuildDebugCommand(const std::vector<std::wstring>& args) const;
    std::wstring FriendlyError(const std::wstring& text) const;
    std::vector<std::wstring> BuildGetFormatsArgs(const std::wstring& url) const;

private:
    std::wstring appDir_;
    std::wstring ytDlpPath_;
    std::wstring denoPath_;
    std::wstring ffmpegDir_;
    std::wstring cookiesPath_;
    std::wstring downloadsDir_;
    ProxyMode proxyMode_ = ProxyMode::Custom;
    std::wstring proxyUrl_ = L"http://127.0.0.1:7897";

    std::vector<std::wstring> CommonArgs() const;
    ProcessResult RunTool(
        const std::vector<std::wstring>& args,
        std::function<void(const std::wstring&)> onOutput = nullptr) const;
};

std::wstring GetExecutableDirectoryPortable();
