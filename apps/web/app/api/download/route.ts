import type { DownloadEvent, DownloadMode, MediaFormat } from "@/lib/contracts";
import { downloadMedia } from "@/lib/media-service";
import { enforceRateLimit } from "@/lib/rate-limit";
import { authorizeRequest, validateMediaUrl } from "@/lib/security";

export const maxDuration = 300;
export const dynamic = "force-dynamic";

export async function POST(request: Request): Promise<Response> {
  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const emit = (event: DownloadEvent) => controller.enqueue(encoder.encode(`${JSON.stringify(event)}\n`));
      try {
        authorizeRequest(request);
        enforceRateLimit(request, "download");
        const body = await request.json();
        const url = await validateMediaUrl(body?.url);
        const mode = validateMode(body?.mode);
        const selectedFormat = validateSelectedFormat(body?.selectedFormat);
        emit({ type: "stage", stage: "starting" });
        await downloadMedia({ url, mode, selectedFormat, signal: request.signal, emit });
      } catch (error) {
        const code = error instanceof Error ? error.message : "DOWNLOAD_FAILED";
        console.error("[readydownloader:download]", code);
        emit({ type: "error", code: publicErrorCode(code) });
      } finally {
        controller.close();
      }
    },
    cancel() {
      // Cancelling the HTTP stream aborts request.signal; child processes listen to it.
    }
  });
  return new Response(stream, {
    headers: {
      "Content-Type": "application/x-ndjson; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff"
    }
  });
}

function validateMode(value: unknown): DownloadMode {
  if (value === "best" || value === "iphone" || value === "selected") return value;
  throw new Error("INVALID_MODE");
}

function validateSelectedFormat(value: unknown): MediaFormat | undefined {
  if (value == null) return undefined;
  if (typeof value !== "object") throw new Error("MISSING_FORMAT");
  const format = value as MediaFormat;
  if (typeof format.id !== "string" || format.id.length > 128 || typeof format.isVideoOnly !== "boolean") {
    throw new Error("MISSING_FORMAT");
  }
  return format;
}

function publicErrorCode(code: string): string {
  const allowed = new Set(["UNAUTHORIZED", "RATE_LIMITED", "INVALID_URL", "UNSAFE_URL", "UNREACHABLE_URL", "AUTH_REQUIRED", "UNSUPPORTED_URL", "MEDIA_UNAVAILABLE", "TOOL_TIMEOUT", "CANCELLED", "FILE_TOO_LARGE", "MISSING_FORMAT", "STORAGE_NOT_CONFIGURED"]);
  return allowed.has(code) ? code : "DOWNLOAD_FAILED";
}
