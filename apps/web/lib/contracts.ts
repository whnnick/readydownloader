export type AppLanguage = "zh-CN" | "en";
export type DownloadMode = "best" | "iphone" | "selected";

export interface MediaFormat {
  id: string;
  ext: string;
  resolution: string;
  width: number | null;
  height: number;
  fps: number | null;
  videoCodec: string;
  audioCodec: string;
  fileSize: number | null;
  bitrate: number | null;
  isVideoOnly: boolean;
}

export interface MediaInfo {
  title: string;
  extractor: string;
  webpageUrl: string;
  thumbnail: string | null;
  duration: number | null;
  formats: MediaFormat[];
}

export type DownloadEvent =
  | { type: "stage"; stage: "starting" | "downloading" | "converting" | "uploading"; detail?: string }
  | { type: "progress"; percent: number | null; speed?: string; eta?: string }
  | { type: "done"; url: string; filename: string; size: number; expiresAt: string }
  | { type: "error"; code: string };
