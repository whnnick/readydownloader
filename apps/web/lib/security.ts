import { lookup } from "node:dns/promises";
import { isIP } from "node:net";
import { timingSafeEqual } from "node:crypto";

const localNames = new Set(["localhost", "localhost.localdomain"]);
const supportedDomains = [
  "youtube.com", "youtu.be", "instagram.com", "tiktok.com", "douyin.com",
  "bilibili.com", "b23.tv", "vimeo.com", "facebook.com", "fb.watch",
  "x.com", "twitter.com", "twitch.tv", "dailymotion.com", "reddit.com",
  "redd.it", "xiaohongshu.com", "xiaohongshu.cn", "acfun.cn", "douyu.com",
  "huya.com", "iqiyi.com", "youku.com", "weibo.com", "weibo.cn", "kuaishou.com"
];

export async function validateMediaUrl(value: unknown): Promise<URL> {
  if (typeof value !== "string" || value.length === 0 || value.length > 2048) {
    throw new Error("INVALID_URL");
  }
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error("INVALID_URL");
  }
  if (!["http:", "https:"].includes(url.protocol) || url.username || url.password) {
    throw new Error("INVALID_URL");
  }
  if (url.port && !["80", "443"].includes(url.port)) throw new Error("UNSAFE_URL");
  const hostname = url.hostname.toLowerCase().replace(/\.$/, "");
  if (!hostname || localNames.has(hostname) || hostname.endsWith(".local")) throw new Error("UNSAFE_URL");
  if (isIP(hostname)) {
    if (isPrivateAddress(hostname)) throw new Error("UNSAFE_URL");
    throw new Error("UNSUPPORTED_URL");
  } else {
    if (!isSupportedSource(hostname)) throw new Error("UNSUPPORTED_URL");
    let addresses: { address: string }[];
    try {
      addresses = await lookup(hostname, { all: true, verbatim: true });
    } catch {
      throw new Error("UNREACHABLE_URL");
    }
    if (addresses.length === 0 || addresses.some(({ address }) => isPrivateAddress(address))) {
      throw new Error("UNSAFE_URL");
    }
  }
  return url;
}

export function isSupportedSource(hostname: string): boolean {
  const normalized = hostname.toLowerCase().replace(/\.$/, "");
  return supportedDomains.some((domain) => normalized === domain || normalized.endsWith(`.${domain}`));
}

export function authorizeRequest(request: Request): void {
  const expected = process.env.READYDOWNLOADER_ACCESS_TOKEN;
  if (!expected) return;
  const actual = request.headers.get("x-readydownloader-token") ?? "";
  const expectedBuffer = Buffer.from(expected);
  const actualBuffer = Buffer.from(actual);
  if (expectedBuffer.length !== actualBuffer.length || !timingSafeEqual(expectedBuffer, actualBuffer)) {
    throw new Error("UNAUTHORIZED");
  }
}

export function isPrivateAddress(address: string): boolean {
  const normalized = address.toLowerCase();
  if (normalized === "::1" || normalized === "::" || normalized.startsWith("fe80:") || normalized.startsWith("fc") || normalized.startsWith("fd")) {
    return true;
  }
  if (normalized.startsWith("::ffff:")) return isPrivateAddress(normalized.slice(7));
  const parts = normalized.split(".").map(Number);
  if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) return false;
  const [a, b] = parts;
  return a === 0 || a === 10 || a === 127 || (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) || a >= 224;
}
