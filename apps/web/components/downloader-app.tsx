"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { trackProductEvent } from "@/lib/analytics";
import type { AppLanguage, DownloadEvent, DownloadMode, MediaFormat, MediaInfo } from "@/lib/contracts";

type Status = {
  kind: "neutral" | "progress" | "success" | "error";
  code: "waiting" | "analyzing" | "analyzed" | "preparing" | "downloading" | "converting" | "uploading" | "completed" | "cancelled" | "clipboardDenied" | "failed";
  count?: number;
  percent?: number | null;
  speed?: string;
  eta?: string;
  filename?: string;
  errorCode?: string;
};
type Copy = ReturnType<typeof copyFor>;

export function DownloaderApp() {
  const [language, setLanguage] = useState<AppLanguage>("zh-CN");
  const [url, setUrl] = useState("");
  const [accessToken, setAccessToken] = useState("");
  const [media, setMedia] = useState<MediaInfo | null>(null);
  const [mode, setMode] = useState<DownloadMode>("iphone");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [working, setWorking] = useState(false);
  const [progress, setProgress] = useState<number | null>(null);
  const [result, setResult] = useState<Extract<DownloadEvent, { type: "done" }> | null>(null);
  const [status, setStatus] = useState<Status>({ kind: "neutral", code: "waiting" });
  const abortRef = useRef<AbortController | null>(null);
  const copy = copyFor(language);

  useEffect(() => {
    const storedLanguage = localStorage.getItem("readydownloader-language");
    const storedToken = localStorage.getItem("readydownloader-access-token");
    if (storedLanguage === "en" || storedLanguage === "zh-CN") setLanguage(storedLanguage);
    if (storedToken) setAccessToken(storedToken);
  }, []);

  useEffect(() => {
    document.documentElement.lang = language;
    document.title = language === "zh-CN" ? "ReadyDownloader — 在线视频下载" : "ReadyDownloader — Online Video Downloader";
    localStorage.setItem("readydownloader-language", language);
  }, [language]);

  const selectedFormat = useMemo(
    () => media?.formats.find((format) => format.id === selectedId),
    [media, selectedId]
  );
  const canAnalyze = isHttpUrl(url) && !working;
  const canDownload = Boolean(media && !working && (mode !== "selected" || selectedFormat));

  async function analyze() {
    if (!canAnalyze) return;
    trackProductEvent("analyze_click", { language });
    const controller = new AbortController();
    abortRef.current = controller;
    setWorking(true);
    setResult(null);
    setProgress(null);
    setMedia(null);
    setSelectedId(null);
    setStatus({ kind: "progress", code: "analyzing" });
    try {
      const response = await fetch("/api/formats", {
        method: "POST",
        headers: requestHeaders(accessToken),
        body: JSON.stringify({ url: url.trim() }),
        signal: controller.signal
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.code || "ANALYZE_FAILED");
      setMedia(payload as MediaInfo);
      setSelectedId((payload as MediaInfo).formats[0]?.id ?? null);
      setStatus({
        kind: "success",
        code: "analyzed",
        count: (payload as MediaInfo).formats.length
      });
      trackProductEvent("analyze_complete", { language, formatCount: (payload as MediaInfo).formats.length });
    } catch (error) {
      if ((error as Error).name !== "AbortError") {
        setStatus(errorStatus(error));
        trackProductEvent("analyze_error", { language });
      }
    } finally {
      setWorking(false);
      abortRef.current = null;
    }
  }

  async function download() {
    if (!canDownload || !media) return;
    trackProductEvent("download_click", { language, mode });
    const controller = new AbortController();
    abortRef.current = controller;
    setWorking(true);
    setResult(null);
    setProgress(null);
    setStatus({ kind: "progress", code: "preparing" });
    try {
      const response = await fetch("/api/download", {
        method: "POST",
        headers: requestHeaders(accessToken),
        body: JSON.stringify({ url: url.trim(), mode, selectedFormat }),
        signal: controller.signal
      });
      if (!response.ok || !response.body) throw new Error("DOWNLOAD_FAILED");
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      while (true) {
        const { done, value } = await reader.read();
        buffer += decoder.decode(value, { stream: !done });
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";
        for (const line of lines) if (line.trim()) handleDownloadEvent(JSON.parse(line) as DownloadEvent);
        if (done) break;
      }
    } catch (error) {
      if ((error as Error).name !== "AbortError") {
        setStatus(errorStatus(error));
        trackProductEvent("download_error", { language, mode });
      }
    } finally {
      setWorking(false);
      abortRef.current = null;
    }
  }

  function handleDownloadEvent(event: DownloadEvent) {
    if (event.type === "progress") {
      setProgress(event.percent);
      setStatus({ kind: "progress", code: "downloading", percent: event.percent, speed: event.speed, eta: event.eta });
    } else if (event.type === "stage") {
      const stages: Record<typeof event.stage, Status["code"]> = {
        starting: "preparing",
        downloading: "downloading",
        converting: "converting",
        uploading: "uploading"
      } as const;
      setStatus({ kind: "progress", code: stages[event.stage] });
    } else if (event.type === "error") {
      setStatus(errorStatus(new Error(event.code)));
      trackProductEvent("download_error", { language, mode });
    } else {
      setResult(event);
      setProgress(100);
      setStatus({ kind: "success", code: "completed", filename: event.filename });
      trackProductEvent("download_complete", { language, mode });
    }
  }

  function cancel() {
    abortRef.current?.abort();
    setWorking(false);
    setStatus({ kind: "neutral", code: "cancelled" });
  }

  function clearUrl() {
    setUrl("");
    setMedia(null);
    setResult(null);
    setProgress(null);
    setSelectedId(null);
    setStatus({ kind: "neutral", code: "waiting" });
  }

  async function paste() {
    try {
      const text = await navigator.clipboard.readText();
      if (text) {
        setUrl(text.trim());
        setMedia(null);
        setResult(null);
      }
    } catch {
      setStatus({ kind: "error", code: "clipboardDenied" });
    }
  }

  function changeLanguage(nextLanguage: AppLanguage) {
    if (nextLanguage !== language) {
      trackProductEvent("language_change", { language: nextLanguage });
      setLanguage(nextLanguage);
    }
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <a className="brand" href="#top" aria-label="ReadyDownloader">
          <span className="brand-mark" aria-hidden="true"><DownloadIcon /></span>
          <span>ReadyDownloader</span>
        </a>
        <div className="topbar-actions">
          <span className="platform-badge">Web Beta</span>
          <div className="language-switch" aria-label={copy.language}>
            <button className={language === "zh-CN" ? "active" : ""} onClick={() => changeLanguage("zh-CN")}>中文</button>
            <button className={language === "en" ? "active" : ""} onClick={() => changeLanguage("en")}>EN</button>
          </div>
          <a className="icon-link" href="https://github.com/whnnick/readydownloader" target="_blank" rel="noreferrer" aria-label="GitHub" onClick={() => trackProductEvent("github_click", { language })}><GithubIcon /></a>
        </div>
      </header>

      <section className="workspace" id="top">
        <div className="hero">
          <div>
            <p className="eyebrow">READY SUITE · MEDIA TOOL</p>
            <h1>{copy.heroTitle}</h1>
            <p>{copy.heroDetail}</p>
          </div>
          <div className="privacy-note"><ShieldIcon /><span>{copy.privacy}</span></div>
        </div>

        <section className="panel link-panel">
          <PanelHeader title={copy.videoUrl} subtitle={copy.videoUrlDetail} />
          <div className="url-row">
            <div className={`url-field ${url && !isHttpUrl(url) ? "invalid" : ""}`}>
              <LinkIcon />
              <input
                value={url}
                onChange={(event) => { setUrl(event.target.value); if (media) setMedia(null); }}
                onKeyDown={(event) => { if (event.key === "Enter") void analyze(); }}
                placeholder={copy.urlPlaceholder}
                disabled={working}
                aria-label={copy.videoUrl}
              />
              {url && !working && <button className="clear-button" onClick={clearUrl} aria-label={copy.clear}>×</button>}
            </div>
            <button className="secondary-button" onClick={() => void paste()} disabled={working}>{copy.paste}</button>
            <button className="primary-button" onClick={() => void analyze()} disabled={!canAnalyze}><SearchIcon />{copy.analyze}</button>
          </div>
          {url && !isHttpUrl(url) ? <p className="field-error">{copy.invalidUrl}</p> : <p className="field-hint">{copy.urlHint}</p>}
          <details className="access-settings">
            <summary>{copy.accessSettings}</summary>
            <form onSubmit={(event) => event.preventDefault()}>
              <input type="text" name="username" value="readydownloader" autoComplete="username" readOnly hidden />
              <label>
                <span>{copy.accessCode}</span>
                <input type="password" autoComplete="current-password" value={accessToken} onChange={(event) => { setAccessToken(event.target.value); localStorage.setItem("readydownloader-access-token", event.target.value); }} placeholder={copy.optional} />
              </label>
            </form>
          </details>
        </section>

        <section className="panel">
          <PanelHeader title={copy.downloadSettings} subtitle={copy.downloadSettingsDetail} />
          <div className="settings-grid">
            <div className="setting-block">
              <span className="field-label">{copy.downloadMode}</span>
              <div className="segmented-control">
                {(["best", "iphone", "selected"] as DownloadMode[]).map((item) => (
                  <button key={item} className={mode === item ? "active" : ""} onClick={() => setMode(item)} disabled={working}>{copy.modeNames[item]}</button>
                ))}
              </div>
              <p>{copy.modeDetails[mode]}</p>
            </div>
            <div className="setting-block">
              <span className="field-label">{copy.saveLocation}</span>
              <div className="save-location"><FolderIcon /><span>{copy.browserDownloads}</span><span className="managed-badge">{copy.browserManaged}</span></div>
              <p>{copy.saveLocationDetail}</p>
            </div>
          </div>
          <div className="panel-action">
            {mode === "selected" && !selectedFormat && <span className="selection-hint">{copy.selectFormat}</span>}
            <button className="primary-button download-button" onClick={() => void download()} disabled={!canDownload}><DownloadSmallIcon />{copy.downloadLabels[mode]}</button>
          </div>
        </section>

        <section className="panel formats-panel">
          <PanelHeader title={copy.availableFormats} subtitle={media ? copy.mediaSummary(media.title, media.formats.length) : copy.availableFormatsDetail} />
          {media?.formats.length ? (
            <div className="table-scroll">
              <table>
                <thead><tr>{copy.columns.map((column) => <th key={column}>{column}</th>)}</tr></thead>
                <tbody>{media.formats.map((format) => (
                  <tr key={format.id} className={selectedId === format.id ? "selected" : ""} onClick={() => setSelectedId(format.id)}>
                    <td><span className="radio-dot" />{format.id}</td><td>{format.ext}</td><td>{format.resolution}</td><td>{format.fps ?? "—"}</td><td className="codec">{format.videoCodec}</td><td>{format.isVideoOnly ? copy.videoOnly : format.audioCodec}</td><td>{formatBytes(format.fileSize, language)}</td><td>{format.bitrate ? `${Math.round(format.bitrate)}k` : "—"}</td>
                  </tr>
                ))}</tbody>
              </table>
            </div>
          ) : (
            <div className={`empty-state ${working ? "working" : ""}`}>
              <span className="empty-icon"><SearchLargeIcon /></span>
              <h3>{working ? copy.analyzing : copy.emptyTitle}</h3>
              <p>{working ? copy.analyzingDetail : copy.emptyDetail}</p>
            </div>
          )}
        </section>

        <section className="panel status-panel">
          <PanelHeader title={copy.currentStatus} />
          <div className={`status-card ${status.kind}`}>
            {working ? <span className="spinner" /> : <span className="status-dot" />}
            <div><strong>{statusText(status, copy).title}</strong><p>{statusText(status, copy).detail}</p></div>
            {result && <a className="result-button" href={result.url} target="_blank" rel="noreferrer" download={result.filename} onClick={() => trackProductEvent("file_save_click", { language, mode })}>{copy.saveFile}</a>}
          </div>
          {progress !== null && <div className="progress-track"><span style={{ width: `${Math.max(0, Math.min(100, progress))}%` }} /></div>}
          {working && <button className="cancel-button" onClick={cancel}>{copy.cancel}</button>}
          {result && <p className="retention-note">{copy.retention(new Date(result.expiresAt))}</p>}
        </section>

        <section className="service-boundary">
          <ShieldIcon />
          <div><strong>{copy.boundaryTitle}</strong><p>{copy.boundaryDetail}</p></div>
        </section>
      </section>

      <footer><span>ReadyDownloader · ReadySuite</span><span>{copy.footer}</span></footer>
    </main>
  );
}

function PanelHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return <div className="panel-header"><h2>{title}</h2>{subtitle && <p>{subtitle}</p>}</div>;
}

function requestHeaders(accessToken: string): HeadersInit {
  return { "Content-Type": "application/json", ...(accessToken ? { "x-readydownloader-token": accessToken } : {}) };
}

function isHttpUrl(value: string): boolean {
  try { return ["http:", "https:"].includes(new URL(value.trim()).protocol); } catch { return false; }
}

function formatBytes(value: number | null, language: AppLanguage): string {
  if (!value) return "—";
  return new Intl.NumberFormat(language, { style: "unit", unit: value >= 1e9 ? "gigabyte" : "megabyte", unitDisplay: "short", maximumFractionDigits: 1 }).format(value / (value >= 1e9 ? 1e9 : 1e6));
}

function errorStatus(error: unknown): Status {
  const code = error instanceof Error ? error.message : "DOWNLOAD_FAILED";
  return { kind: "error", code: "failed", errorCode: code };
}

function statusText(status: Status, copy: Copy): { title: string; detail: string } {
  switch (status.code) {
    case "waiting": return { title: copy.waiting, detail: copy.waitingDetail };
    case "analyzing": return { title: copy.analyzing, detail: copy.analyzingDetail };
    case "analyzed": return { title: copy.analyzed, detail: copy.formatCount(status.count ?? 0) };
    case "preparing": return { title: copy.preparing, detail: copy.preparingDetail };
    case "downloading": return {
      title: copy.downloading,
      detail: status.percent == null ? copy.downloadingDetail : copy.progressDetail(status.percent, status.speed, status.eta)
    };
    case "converting": return { title: copy.converting, detail: copy.convertingDetail };
    case "uploading": return { title: copy.uploading, detail: copy.uploadingDetail };
    case "completed": return { title: copy.completed, detail: copy.completedDetail(status.filename ?? "") };
    case "cancelled": return { title: copy.cancelled, detail: copy.cancelledDetail };
    case "clipboardDenied": return { title: copy.clipboardDenied, detail: copy.clipboardDeniedDetail };
    case "failed": return { title: copy.failed, detail: copy.errors[status.errorCode ?? "DOWNLOAD_FAILED"] ?? copy.errors.DOWNLOAD_FAILED };
  }
}

function copyFor(language: AppLanguage) {
  const zh = language === "zh-CN";
  return {
    language: zh ? "语言" : "Language",
    heroTitle: zh ? "下载你需要的视频，保留应有的画质。" : "Download the video you need, at the quality it deserves.",
    heroDetail: zh ? "粘贴公开页面链接，解析可用格式，并下载最高画质或 iPhone 兼容版本。" : "Paste a public media page, inspect its formats, and download the best or iPhone-compatible version.",
    privacy: zh ? "不使用 Cookie，不支持私密内容；临时文件自动删除。" : "No cookies or private media. Temporary files are deleted automatically.",
    videoUrl: zh ? "视频链接" : "Video URL",
    videoUrlDetail: zh ? "支持已验证平台的公开页面。" : "Supports public pages from verified platforms.",
    urlPlaceholder: zh ? "粘贴视频页面链接" : "Paste a video page URL",
    paste: zh ? "粘贴" : "Paste",
    analyze: zh ? "解析链接" : "Analyze URL",
    clear: zh ? "清空链接" : "Clear URL",
    invalidUrl: zh ? "请输入完整的 http:// 或 https:// 页面链接。" : "Enter a complete http:// or https:// page URL.",
    urlHint: zh ? "支持 YouTube、Instagram、TikTok、哔哩哔哩等公开来源；实际可用性取决于来源站点。" : "Supports public YouTube, Instagram, TikTok, Bilibili and other approved sources; availability depends on the source site.",
    accessSettings: zh ? "访问设置" : "Access settings",
    accessCode: zh ? "访问码" : "Access code",
    optional: zh ? "仅在站点启用访问保护时填写" : "Only required when access protection is enabled",
    downloadSettings: zh ? "下载设置" : "Download Settings",
    downloadSettingsDetail: zh ? "选择画质策略；成品将由浏览器保存。" : "Choose a quality strategy; your browser saves the result.",
    downloadMode: zh ? "下载方式" : "Download Mode",
    modeNames: { best: zh ? "最高画质" : "Best Quality", iphone: zh ? "iPhone 兼容" : "iPhone Compatible", selected: zh ? "指定格式" : "Selected Format" },
    modeDetails: {
      best: zh ? "自动下载可用的最高画质，并在需要时合并音频。" : "Downloads the best available quality and merges audio when needed.",
      iphone: zh ? "检查成品编码，需要时转换为 H.264、AAC 和 yuv420p。" : "Checks the result and converts to H.264, AAC and yuv420p when needed.",
      selected: zh ? "使用下方选中的格式；纯视频格式会自动补充音频。" : "Uses the selected format and adds audio to video-only streams."
    },
    saveLocation: zh ? "保存位置" : "Save Location",
    browserDownloads: zh ? "浏览器下载目录" : "Browser Downloads",
    browserManaged: zh ? "浏览器管理" : "Browser managed",
    saveLocationDetail: zh ? "出于浏览器安全限制，网站不能预先指定你的本地文件夹。" : "Browser security prevents the site from preselecting a local folder.",
    selectFormat: zh ? "请先在下方选择一个格式。" : "Select a format below first.",
    downloadLabels: { best: zh ? "下载最高画质" : "Download Best Quality", iphone: zh ? "下载 iPhone 兼容视频" : "Download for iPhone", selected: zh ? "下载所选格式" : "Download Selected Format" },
    availableFormats: zh ? "可用画质" : "Available Formats",
    availableFormatsDetail: zh ? "解析链接后可在这里查看视频格式。" : "Analyze the URL to inspect available video formats.",
    mediaSummary: (title: string, count: number) => zh ? `${title} · 共 ${count} 个视频格式` : `${title} · ${count} video format(s)`,
    columns: zh ? ["格式", "封装", "分辨率", "帧率", "视频编码", "音频编码", "大小", "码率"] : ["Format", "Container", "Resolution", "FPS", "Video Codec", "Audio Codec", "Size", "Bitrate"],
    videoOnly: zh ? "仅视频" : "Video only",
    emptyTitle: zh ? "等待解析" : "Waiting to analyze",
    emptyDetail: zh ? "点击“解析链接”查看可用画质。" : "Choose Analyze URL to inspect available quality.",
    currentStatus: zh ? "当前状态" : "Current Status",
    waiting: zh ? "等待解析" : "Waiting to analyze",
    waitingDetail: zh ? "粘贴公开视频页面链接后开始。" : "Paste a public media page URL to begin.",
    analyzing: zh ? "正在解析链接" : "Analyzing URL",
    analyzingDetail: zh ? "正在读取视频信息和可用格式…" : "Reading media metadata and available formats…",
    analyzed: zh ? "解析完成" : "Analysis complete",
    formatCount: (count: number) => zh ? `找到 ${count} 个视频格式，可以选择下载方式。` : `Found ${count} video format(s). Choose a download mode.`,
    preparing: zh ? "准备下载" : "Preparing download",
    preparingDetail: zh ? "正在创建安全的临时任务…" : "Creating a secure temporary job…",
    downloading: zh ? "正在下载" : "Downloading",
    downloadingDetail: zh ? "正在从来源站点读取并合并媒体流…" : "Fetching and merging media streams from the source…",
    progressDetail: (percent: number | null, speed?: string, eta?: string) => zh ? `已完成 ${percent ?? 0}%${speed ? ` · ${speed}` : ""}${eta ? ` · 剩余 ${eta}` : ""}` : `${percent ?? 0}% complete${speed ? ` · ${speed}` : ""}${eta ? ` · ETA ${eta}` : ""}`,
    converting: zh ? "正在生成 iPhone 兼容版本" : "Creating iPhone-compatible video",
    convertingDetail: zh ? "正在转换为 H.264、AAC 和 yuv420p…" : "Converting to H.264, AAC and yuv420p…",
    uploading: zh ? "正在准备下载文件" : "Preparing download file",
    uploadingDetail: zh ? "正在上传到临时下载空间…" : "Uploading to temporary download storage…",
    completed: zh ? "下载文件已就绪" : "Download is ready",
    completedDetail: (filename: string) => zh ? `已生成：${filename}` : `Created: ${filename}`,
    saveFile: zh ? "保存文件" : "Save File",
    cancel: zh ? "取消当前操作" : "Cancel Current Operation",
    cancelled: zh ? "操作已取消" : "Operation cancelled",
    cancelledDetail: zh ? "可以修改链接或下载方式后重试。" : "Change the URL or mode and try again.",
    retention: (date: Date) => zh ? `临时文件预计在 ${date.toLocaleString("zh-CN")} 前后删除，请及时保存。` : `Temporary file is scheduled for deletion around ${date.toLocaleString("en")}—save it promptly.`,
    failed: zh ? "操作失败" : "Operation failed",
    clipboardDenied: zh ? "无法读取剪贴板" : "Clipboard access denied",
    clipboardDeniedDetail: zh ? "请按 ⌘V 或 Ctrl+V 手动粘贴链接。" : "Paste manually with ⌘V or Ctrl+V.",
    boundaryTitle: zh ? "公开内容与合理使用" : "Public media and responsible use",
    boundaryDetail: zh ? "Web 版不接收 Cookie、不绕过 DRM，也不访问登录或私密内容。请只下载你有权保存的内容。" : "The web app accepts no cookies, bypasses no DRM, and does not access private or logged-in media. Only save content you are authorized to download.",
    footer: zh ? "开源 · 中英文 · macOS 优先" : "Open source · Bilingual · macOS first",
    errors: {
      INVALID_URL: zh ? "链接格式不正确。" : "The URL is invalid.",
      UNSAFE_URL: zh ? "出于安全原因，不能访问本地或私有网络地址。" : "Local and private-network URLs are blocked.",
      UNREACHABLE_URL: zh ? "无法解析该站点地址。" : "The site address could not be resolved.",
      UNAUTHORIZED: zh ? "访问码不正确。" : "The access code is incorrect.",
      RATE_LIMITED: zh ? "请求过于频繁，请稍后再试。" : "Too many requests. Try again later.",
      AUTH_REQUIRED: zh ? "该内容需要登录或 Cookie，Web 版不支持。" : "This media requires login or cookies, which the web app does not accept.",
      UNSUPPORTED_URL: zh ? "当前工具不支持这个页面。" : "This page is not supported by the current toolchain.",
      MEDIA_UNAVAILABLE: zh ? "视频不可用、已删除或受地区限制。" : "The media is unavailable, removed, or region-restricted.",
      TOOL_TIMEOUT: zh ? "处理时间超过当前服务限制。" : "Processing exceeded the service time limit.",
      FILE_TOO_LARGE: zh ? "视频超过当前 Web 版的文件大小限制。" : "The video exceeds the current web file-size limit.",
      MISSING_FORMAT: zh ? "请先选择一个视频格式。" : "Select a video format first.",
      STORAGE_NOT_CONFIGURED: zh ? "临时下载存储尚未配置。" : "Temporary download storage is not configured.",
      ANALYZE_FAILED: zh ? "解析失败，请检查链接或稍后重试。" : "Analysis failed. Check the URL and try again.",
      DOWNLOAD_FAILED: zh ? "下载失败，请稍后重试或改用客户端。" : "Download failed. Try again later or use the desktop app."
    } as Record<string, string>
  };
}

function DownloadIcon() { return <svg viewBox="0 0 24 24"><path d="M12 3v11m0 0 4-4m-4 4-4-4"/><path d="M5 19h14"/></svg>; }
function DownloadSmallIcon() { return <svg viewBox="0 0 24 24"><path d="M12 4v10m0 0 4-4m-4 4-4-4"/><circle cx="12" cy="12" r="9"/></svg>; }
function SearchIcon() { return <svg viewBox="0 0 24 24"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m15.5 15.5 5 5"/><path d="M10.5 7.5v6m-3-3h6"/></svg>; }
function SearchLargeIcon() { return <svg viewBox="0 0 32 32"><circle cx="14" cy="14" r="8"/><path d="m20 20 7 7"/><path d="m14 10 .9 2.3L17 13l-2.1.8L14 16l-.9-2.2L11 13l2.1-.7z"/></svg>; }
function LinkIcon() { return <svg viewBox="0 0 24 24"><path d="M9.5 14.5 14.5 9"/><path d="M7 17H5.5a4.5 4.5 0 0 1 0-9H9"/><path d="M15 8h3.5a4.5 4.5 0 0 1 0 9H15"/></svg>; }
function FolderIcon() { return <svg viewBox="0 0 24 24"><path d="M3 7.5h7l2-2h9v14H3z"/></svg>; }
function ShieldIcon() { return <svg viewBox="0 0 24 24"><path d="M12 3 20 6v5c0 5-3.4 8.2-8 10-4.6-1.8-8-5-8-10V6z"/><path d="m8.5 12 2.2 2.2 4.8-5"/></svg>; }
function GithubIcon() { return <svg viewBox="0 0 24 24"><path d="M12 2.5a9.5 9.5 0 0 0-3 18.5c.5.1.7-.2.7-.5v-2c-2.8.6-3.4-1.2-3.4-1.2-.5-1.1-1.1-1.4-1.1-1.4-.9-.6.1-.6.1-.6 1 0 1.6 1 1.6 1 .9 1.6 2.4 1.1 3 .9.1-.7.4-1.1.7-1.4-2.3-.3-4.7-1.1-4.7-5A3.9 3.9 0 0 1 7 8.1c-.1-.3-.5-1.3.1-2.7 0 0 .8-.3 2.8 1.1a9.6 9.6 0 0 1 5.1 0c2-1.4 2.8-1.1 2.8-1.1.6 1.4.2 2.4.1 2.7a3.9 3.9 0 0 1 1 2.7c0 3.9-2.4 4.7-4.7 5 .4.3.7 1 .7 1.9v2.8c0 .3.2.6.7.5A9.5 9.5 0 0 0 12 2.5Z"/></svg>; }
