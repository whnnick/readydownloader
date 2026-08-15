import { createHash } from "node:crypto";
import { chmod, mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const version = "2026.07.04";
const assets = {
  darwin: {
    name: "yt-dlp_macos",
    sha256: "498bd0dae17855c599d371d68ec5bafc439a9d8640e838be25c765a9792f261b"
  },
  linux: {
    name: "yt-dlp_linux",
    sha256: "6bbb3d314cde4febe36e5fa1d55462e29c974f63444e707871834f6d8cc210ae"
  }
};
const asset = assets[process.platform];
if (!asset) throw new Error(`Unsupported yt-dlp build platform: ${process.platform}`);
const expectedSha256 = asset.sha256;
const outputDirectory = path.join(process.cwd(), ".tools");
const outputPath = path.join(outputDirectory, "yt-dlp");
const temporaryPath = `${outputPath}.download`;
const url = `https://github.com/yt-dlp/yt-dlp/releases/download/${version}/${asset.name}`;

async function sha256(filePath) {
  return createHash("sha256").update(await readFile(filePath)).digest("hex");
}

await mkdir(outputDirectory, { recursive: true });

try {
  if ((await sha256(outputPath)) === expectedSha256) {
    await chmod(outputPath, 0o755);
    console.log(`yt-dlp ${version} already verified.`);
    process.exit(0);
  }
} catch {
  // Missing or stale tools are replaced below.
}

const response = await fetch(url, { redirect: "follow" });
if (!response.ok) {
  throw new Error(`Failed to download yt-dlp: HTTP ${response.status}`);
}
await writeFile(temporaryPath, Buffer.from(await response.arrayBuffer()));
const actualSha256 = await sha256(temporaryPath);
if (actualSha256 !== expectedSha256) {
  await rm(temporaryPath, { force: true });
  throw new Error(`yt-dlp SHA-256 mismatch: ${actualSha256}`);
}
await rename(temporaryPath, outputPath);
await chmod(outputPath, 0o755);
console.log(`yt-dlp ${version} downloaded and verified.`);
