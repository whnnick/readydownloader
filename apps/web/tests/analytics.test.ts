import { describe, expect, it } from "vitest";
import { analyticsPayload } from "../lib/analytics";

describe("analyticsPayload", () => {
  it("records language without media input", () => {
    expect(analyticsPayload("analyze_click", { language: "zh-CN" })).toEqual({
      language: "zh-CN"
    });
  });

  it("records only the selected download mode", () => {
    expect(analyticsPayload("download_click", { language: "en", mode: "iphone" })).toEqual({
      language: "en",
      mode: "iphone"
    });
  });

  it("normalizes the non-sensitive format count", () => {
    expect(analyticsPayload("analyze_complete", { language: "en", formatCount: 8.9 })).toEqual({
      language: "en",
      format_count: 8
    });
  });
});
