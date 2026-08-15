import { del, list } from "@vercel/blob";
import { getRetentionHours } from "@/lib/media-service";

export const maxDuration = 120;
export const dynamic = "force-dynamic";

export async function GET(request: Request): Promise<Response> {
  const secret = process.env.CRON_SECRET;
  if (!secret || request.headers.get("authorization") !== `Bearer ${secret}`) {
    return Response.json({ code: "UNAUTHORIZED" }, { status: 401 });
  }
  const cutoff = Date.now() - getRetentionHours() * 60 * 60 * 1_000;
  let cursor: string | undefined;
  let deleted = 0;
  do {
    const page = await list({ prefix: "downloads/", limit: 1_000, cursor });
    const expired = page.blobs.filter((blob) => new Date(blob.uploadedAt).getTime() < cutoff).map((blob) => blob.url);
    if (expired.length) {
      await del(expired);
      deleted += expired.length;
    }
    cursor = page.hasMore ? page.cursor : undefined;
  } while (cursor);
  return Response.json({ deleted });
}
