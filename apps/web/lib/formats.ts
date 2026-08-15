import type { MediaFormat, MediaInfo } from "./contracts";

type RawFormat = {
  format_id?: string;
  ext?: string;
  width?: number;
  height?: number;
  fps?: number;
  vcodec?: string;
  acodec?: string;
  filesize?: number;
  filesize_approx?: number;
  tbr?: number;
};

type RawMedia = {
  title?: string;
  extractor_key?: string;
  extractor?: string;
  webpage_url?: string;
  original_url?: string;
  thumbnail?: string;
  duration?: number;
  formats?: RawFormat[];
};

export function parseMediaInfo(raw: unknown, requestedUrl: string): MediaInfo {
  if (!raw || typeof raw !== "object") throw new Error("INVALID_MEDIA_RESPONSE");
  const media = raw as RawMedia;
  const formats = (media.formats ?? [])
    .map(parseFormat)
    .filter((format): format is MediaFormat => format !== null)
    .sort(sortFormats);

  return {
    title: media.title?.trim() || "Untitled video",
    extractor: media.extractor_key || media.extractor || "generic",
    webpageUrl: media.webpage_url || media.original_url || requestedUrl,
    thumbnail: media.thumbnail || null,
    duration: finiteNumber(media.duration),
    formats
  };
}

function parseFormat(raw: RawFormat): MediaFormat | null {
  const id = raw.format_id?.trim() ?? "";
  const height = finiteNumber(raw.height);
  const videoCodec = raw.vcodec?.trim() ?? "";
  if (!id || id.startsWith("sb") || !height || height <= 0 || !videoCodec || videoCodec === "none") {
    return null;
  }
  const width = finiteNumber(raw.width);
  const audioCodec = raw.acodec?.trim() ?? "";
  return {
    id,
    ext: raw.ext?.trim() || "—",
    resolution: width ? `${width}x${height}` : `${height}p`,
    width,
    height,
    fps: finiteNumber(raw.fps),
    videoCodec,
    audioCodec,
    fileSize: finiteNumber(raw.filesize) ?? finiteNumber(raw.filesize_approx),
    bitrate: finiteNumber(raw.tbr),
    isVideoOnly: !audioCodec || audioCodec === "none"
  };
}

function finiteNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function sortFormats(left: MediaFormat, right: MediaFormat): number {
  if (left.height !== right.height) return right.height - left.height;
  if ((left.fps ?? 0) !== (right.fps ?? 0)) return (right.fps ?? 0) - (left.fps ?? 0);
  if (left.ext !== right.ext) return left.ext.localeCompare(right.ext);
  return left.id.localeCompare(right.id);
}

export function formatSelector(mode: "best" | "iphone" | "selected", selected?: MediaFormat): string {
  if (mode === "best") return "bv*+ba/b";
  if (mode === "iphone") return "bv[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4][vcodec^=avc1]/bv*+ba/b";
  if (!selected) throw new Error("MISSING_FORMAT");
  return selected.isVideoOnly ? `${selected.id}+ba` : selected.id;
}
