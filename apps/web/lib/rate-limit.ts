type Bucket = { hits: number[] };

const globalBuckets = globalThis as typeof globalThis & {
  __readyDownloaderRateBuckets?: Map<string, Bucket>;
};
const buckets = globalBuckets.__readyDownloaderRateBuckets ?? new Map<string, Bucket>();
globalBuckets.__readyDownloaderRateBuckets = buckets;

export function enforceRateLimit(request: Request, action: "analyze" | "download"): void {
  const ip = (request.headers.get("x-forwarded-for") ?? "unknown").split(",")[0].trim();
  const now = Date.now();
  const windowMs = action === "download" ? 60 * 60 * 1000 : 10 * 60 * 1000;
  const limit = action === "download" ? 2 : 8;
  const key = `${action}:${ip}`;
  const recent = (buckets.get(key)?.hits ?? []).filter((timestamp) => now - timestamp < windowMs);
  if (recent.length >= limit) throw new Error("RATE_LIMITED");
  recent.push(now);
  buckets.set(key, { hits: recent });

  if (buckets.size > 2_000) {
    for (const [bucketKey, bucket] of buckets) {
      if (bucket.hits.every((timestamp) => now - timestamp >= 60 * 60 * 1000)) buckets.delete(bucketKey);
    }
  }
}
