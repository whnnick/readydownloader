import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Next.js 16 otherwise generates repository-internal AI instruction files.
  agentRules: false,
  outputFileTracingIncludes: {
    "/api/**/*": [
      "./.tools/**/*",
      "./node_modules/ffmpeg-static/ffmpeg",
      "./node_modules/ffprobe-static/bin/**/*"
    ]
  }
};

export default nextConfig;
