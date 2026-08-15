import { describe, expect, it } from "vitest";
import { formatSelector, parseMediaInfo } from "../lib/formats";

describe("parseMediaInfo", () => {
  it("filters non-video and storyboard formats and sorts by quality", () => {
    const result = parseMediaInfo({
      title: "Fixture",
      extractor_key: "FixtureExtractor",
      formats: [
        { format_id: "audio", acodec: "aac", vcodec: "none" },
        { format_id: "sb0", width: 320, height: 180, vcodec: "mhtml" },
        { format_id: "720", ext: "mp4", width: 1280, height: 720, fps: 30, vcodec: "h264", acodec: "none" },
        { format_id: "1080", ext: "webm", width: 1920, height: 1080, fps: 60, vcodec: "vp9", acodec: "none", filesize_approx: 42_000_000 }
      ]
    }, "https://example.com/video");

    expect(result.title).toBe("Fixture");
    expect(result.extractor).toBe("FixtureExtractor");
    expect(result.formats.map((format) => format.id)).toEqual(["1080", "720"]);
    expect(result.formats[0]).toMatchObject({ resolution: "1920x1080", isVideoOnly: true, fileSize: 42_000_000 });
  });
});

describe("formatSelector", () => {
  it("matches the desktop best-quality and iPhone policies", () => {
    expect(formatSelector("best")).toBe("bv*+ba/b");
    expect(formatSelector("iphone")).toContain("vcodec^=avc1");
  });

  it("adds audio to selected video-only streams", () => {
    const selected = parseMediaInfo({ formats: [
      { format_id: "137", ext: "mp4", width: 1920, height: 1080, vcodec: "avc1", acodec: "none" }
    ] }, "https://example.com/video").formats[0];
    expect(formatSelector("selected", selected)).toBe("137+ba");
  });
});
