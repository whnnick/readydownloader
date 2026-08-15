import { describe, expect, it } from "vitest";
import { isPrivateAddress, isSupportedSource, validateMediaUrl } from "../lib/security";

describe("isPrivateAddress", () => {
  it.each(["127.0.0.1", "10.1.2.3", "172.16.0.1", "192.168.1.1", "169.254.1.1", "::1", "fc00::1", "fe80::1"])("blocks %s", (address) => {
    expect(isPrivateAddress(address)).toBe(true);
  });

  it.each(["1.1.1.1", "8.8.8.8", "2606:4700:4700::1111"])("allows public address %s", (address) => {
    expect(isPrivateAddress(address)).toBe(false);
  });
});

describe("validateMediaUrl", () => {
  it.each(["", "not a url", "file:///tmp/video", "http://localhost/video", "http://127.0.0.1/video", "https://user:pass@example.com/video", "https://example.com:8080/video"])("rejects unsafe value %s", async (value) => {
    await expect(validateMediaUrl(value)).rejects.toThrow();
  });

  it.each([
    "https://example.com/video",
    "https://youtube.com.evil.example/video",
    "https://1.1.1.1/video"
  ])("rejects untrusted source %s", async (value) => {
    await expect(validateMediaUrl(value)).rejects.toThrow("UNSUPPORTED_URL");
  });

  it.each(["www.youtube.com", "instagram.com", "WWW.BILIBILI.COM."])("recognizes supported source %s", (hostname) => {
    expect(isSupportedSource(hostname)).toBe(true);
  });
});
