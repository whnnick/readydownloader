import { track } from "@vercel/analytics";
import type { AppLanguage, DownloadMode } from "./contracts";

export type ProductEvent =
  | "analyze_click"
  | "analyze_complete"
  | "analyze_error"
  | "download_click"
  | "download_complete"
  | "download_error"
  | "file_save_click"
  | "github_click"
  | "language_change";

type EventContext = {
  language: AppLanguage;
  mode?: DownloadMode;
  formatCount?: number;
};

export function analyticsPayload(event: ProductEvent, context: EventContext) {
  const properties: Record<string, string | number> = {
    language: context.language
  };

  if ((event.startsWith("download_") || event === "file_save_click") && context.mode) {
    properties.mode = context.mode;
  }
  if (event === "analyze_complete" && context.formatCount != null) {
    properties.format_count = Math.max(0, Math.floor(context.formatCount));
  }

  return properties;
}

export function trackProductEvent(event: ProductEvent, context: EventContext) {
  try {
    track(event, analyticsPayload(event, context));
  } catch {
    // Telemetry must never interrupt analysis or downloads.
  }
}
