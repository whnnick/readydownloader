import { randomUUID } from "node:crypto";
import { createReadStream } from "node:fs";
import { mkdir, readdir, rename, rm, stat, symlink } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { getDownloadUrl, issueSignedToken, presignUrl, put } from "@vercel/blob";
import type { DownloadEvent, DownloadMode, MediaFormat, MediaInfo } from "./contracts";
import { formatSelector, parseMediaInfo } from "./formats";
import { runProcess } from "./process";

const ytDlpPath = path.join(process.cwd(), ".tools", "yt-dlp");
const ffmpegPath = path.join(process.cwd(), "node_modules", "ffmpeg-static", "ffmpeg");
const ffprobePath = path.join(process.cwd(), "node_modules", "ffprobe-static", "bin", process.platform, process.arch, "ffprobe");

export async function analyzeMedia(url: URL, signal?: AbortSignal): Promise<MediaInfo> {
  const tools = await prepareRuntimeTools();
  const result = await runProcess(ytDlpPath, [
    "--ignore-config",
    "--force-ipv4",
    "--no-playlist",
    "--skip-download",
    "--dump-single-json",
    "--socket-timeout", "30",
    "--js-runtimes", `node:${process.execPath}`,
    "--ffmpeg-location", tools.directory,
    url.toString()
  ], { signal, timeoutMs: 90_000 });
  return parseMediaInfo(JSON.parse(result.stdout), url.toString());
}

type DownloadRequest = {
  url: URL;
  mode: DownloadMode;
  selectedFormat?: MediaFormat;
  signal?: AbortSignal;
  emit: (event: DownloadEvent) => void;
};

export async function downloadMedia(request: DownloadRequest): Promise<void> {
  if (!process.env.BLOB_READ_WRITE_TOKEN && !(process.env.BLOB_STORE_ID && process.env.VERCEL_OIDC_TOKEN)) {
    throw new Error("STORAGE_NOT_CONFIGURED");
  }
  const tools = await prepareRuntimeTools();
  const jobDirectory = path.join(os.tmpdir(), `readydownloader-${randomUUID()}`);
  await mkdir(jobDirectory, { recursive: true });
  try {
    request.emit({ type: "stage", stage: "downloading" });
    const selector = formatSelector(request.mode, request.selectedFormat);
    const maxBytes = getMaxOutputBytes();
    const outputTemplate = path.join(jobDirectory, "%(title).120B [%(id)s].%(ext)s");
    const result = await runProcess(ytDlpPath, [
      "--ignore-config",
      "--force-ipv4",
      "--no-playlist",
      "--newline",
      "--socket-timeout", "30",
      "--js-runtimes", `node:${process.execPath}`,
      "--ffmpeg-location", tools.directory,
      "--max-filesize", String(maxBytes),
      "--restrict-filenames",
      "--print", "after_move:filepath",
      "-f", selector,
      ...(request.mode === "iphone" ? ["--merge-output-format", "mp4"] : []),
      "-o", outputTemplate,
      request.url.toString()
    ], {
      signal: request.signal,
      timeoutMs: 270_000,
      onLine: (line) => emitProgress(line, request.emit)
    });

    let outputPath = await findOutputPath(jobDirectory, result.stdout);
    if ((await stat(/* turbopackIgnore: true */ outputPath)).size > maxBytes) throw new Error("FILE_TOO_LARGE");
    if (request.mode === "iphone") {
      outputPath = await makeIPhoneCompatible(outputPath, request);
    }

    request.emit({ type: "stage", stage: "uploading" });
    const file = await stat(/* turbopackIgnore: true */ outputPath);
    const filename = path.basename(outputPath);
    const pathname = `downloads/${new Date().toISOString().slice(0, 10)}/${randomUUID()}-${filename}`;
    await put(pathname, createReadStream(/* turbopackIgnore: true */ outputPath), {
      access: "private",
      addRandomSuffix: false,
      multipart: true,
      cacheControlMaxAge: 3_600
    });
    const retentionHours = getRetentionHours();
    const validUntil = Date.now() + retentionHours * 60 * 60 * 1_000;
    const signedToken = await issueSignedToken({ pathname, operations: ["get"], validUntil });
    const { presignedUrl } = await presignUrl(signedToken, {
      access: "private",
      operation: "get",
      pathname,
      validUntil
    });
    request.emit({
      type: "done",
      url: getDownloadUrl(presignedUrl),
      filename,
      size: file.size,
      expiresAt: new Date(validUntil).toISOString()
    });
  } finally {
    await rm(jobDirectory, { recursive: true, force: true });
  }
}

async function makeIPhoneCompatible(input: string, request: DownloadRequest): Promise<string> {
  const probe = await runProcess(ffprobePath, [
    "-v", "error",
    "-show_entries", "stream=codec_type,codec_name,pix_fmt:format=format_name",
    "-of", "json",
    input
  ], { signal: request.signal, timeoutMs: 30_000 });
  const media = JSON.parse(probe.stdout) as {
    streams?: { codec_type?: string; codec_name?: string; pix_fmt?: string }[];
    format?: { format_name?: string };
  };
  const streams = media.streams ?? [];
  const video = streams.find((stream) => stream.codec_type === "video");
  const compatible = media.format?.format_name?.split(",").includes("mp4") &&
    video?.codec_name === "h264" && ["yuv420p", "yuvj420p"].includes(video.pix_fmt ?? "") &&
    streams.filter((stream) => stream.codec_type === "audio").every((stream) => stream.codec_name === "aac");
  if (compatible) return input;

  request.emit({ type: "stage", stage: "converting" });
  const output = path.join(path.dirname(input), `.iphone-${randomUUID()}.mp4`);
  await runProcess(ffmpegPath, [
    "-hide_banner", "-y", "-i", input,
    "-map", "0:v:0", "-map", "0:a:0?", "-map_metadata", "0",
    "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p",
    "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-tag:v", "avc1",
    "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart",
    output
  ], { signal: request.signal, timeoutMs: 270_000 });
  await rm(input, { force: true });
  await rename(output, input.replace(/\.[^.]+$/, ".mp4"));
  return input.replace(/\.[^.]+$/, ".mp4");
}

async function prepareRuntimeTools(): Promise<{ directory: string }> {
  const directory = path.join(os.tmpdir(), "readydownloader-tools");
  await mkdir(directory, { recursive: true });
  await ensureLink(ffmpegPath, path.join(directory, "ffmpeg"));
  await ensureLink(ffprobePath, path.join(directory, "ffprobe"));
  return { directory };
}

async function ensureLink(source: string, destination: string): Promise<void> {
  try {
    await symlink(source, destination);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
  }
}

async function findOutputPath(directory: string, stdout: string): Promise<string> {
  const printed = stdout.trim().split(/\r?\n/).reverse().find((line) => line.startsWith(directory));
  if (printed) return printed;
  const files = (await readdir(directory)).filter((name) => !name.startsWith("."));
  if (files.length !== 1) throw new Error("MISSING_OUTPUT");
  return path.join(directory, files[0]);
}

function emitProgress(line: string, emit: (event: DownloadEvent) => void): void {
  const match = line.match(/\[download\]\s+([0-9.]+)%.*?(?:at\s+(\S+))?.*?(?:ETA\s+(\S+))?$/i);
  if (!match) return;
  emit({ type: "progress", percent: Number(match[1]), speed: match[2], eta: match[3] });
}

function getMaxOutputBytes(): number {
  const configured = Number(process.env.READYDOWNLOADER_MAX_OUTPUT_MB ?? "500");
  const megabytes = Number.isFinite(configured) ? Math.min(1_000, Math.max(25, configured)) : 500;
  return Math.floor(megabytes * 1024 * 1024);
}

export function getRetentionHours(): number {
  const configured = Number(process.env.READYDOWNLOADER_RETENTION_HOURS ?? "24");
  return Number.isFinite(configured) ? Math.min(72, Math.max(1, configured)) : 24;
}
