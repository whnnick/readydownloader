import { analyzeMedia } from "@/lib/media-service";
import { authorizeRequest, validateMediaUrl } from "@/lib/security";
import { enforceRateLimit } from "@/lib/rate-limit";

export const maxDuration = 120;
export const dynamic = "force-dynamic";

export async function POST(request: Request): Promise<Response> {
  try {
    authorizeRequest(request);
    enforceRateLimit(request, "analyze");
    const body = await request.json();
    const url = await validateMediaUrl(body?.url);
    return Response.json(await analyzeMedia(url, request.signal));
  } catch (error) {
    const code = error instanceof Error ? error.message : "ANALYZE_FAILED";
    console.error("[readydownloader:analyze]", code);
    return Response.json({ code: publicErrorCode(code) }, { status: statusFor(code) });
  }
}

function statusFor(code: string): number {
  if (code === "UNAUTHORIZED") return 401;
  if (code === "RATE_LIMITED") return 429;
  if (["INVALID_URL", "UNSAFE_URL"].includes(code)) return 400;
  return 422;
}

function publicErrorCode(code: string): string {
  const allowed = new Set(["UNAUTHORIZED", "RATE_LIMITED", "INVALID_URL", "UNSAFE_URL", "UNREACHABLE_URL", "AUTH_REQUIRED", "UNSUPPORTED_URL", "MEDIA_UNAVAILABLE", "TOOL_TIMEOUT"]);
  return allowed.has(code) ? code : "ANALYZE_FAILED";
}
