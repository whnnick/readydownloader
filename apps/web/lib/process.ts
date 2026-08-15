import { spawn } from "node:child_process";

type ProcessOptions = {
  signal?: AbortSignal;
  timeoutMs: number;
  onLine?: (line: string) => void;
};

export type ProcessResult = { stdout: string; stderr: string };

export function runProcess(command: string, args: string[], options: ProcessOptions): Promise<ProcessResult> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    let settled = false;
    let lineBuffer = "";

    const finish = (error?: Error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      options.signal?.removeEventListener("abort", abort);
      if (error) reject(error);
      else resolve({ stdout, stderr });
    };
    const abort = () => {
      child.kill("SIGTERM");
      setTimeout(() => child.kill("SIGKILL"), 1_500).unref();
      finish(new Error("CANCELLED"));
    };
    const timeout = setTimeout(() => {
      child.kill("SIGKILL");
      finish(new Error("TOOL_TIMEOUT"));
    }, options.timeoutMs);

    options.signal?.addEventListener("abort", abort, { once: true });
    child.once("error", (error: NodeJS.ErrnoException) => {
      console.error("[readydownloader:process]", command.split(/[\\/]/).at(-1), error.code ?? "SPAWN_FAILED");
      finish(new Error("TOOL_UNAVAILABLE"));
    });
    child.stdout.on("data", (chunk: Buffer) => {
      stdout = appendCapped(stdout, chunk.toString());
    });
    child.stderr.on("data", (chunk: Buffer) => {
      const text = chunk.toString();
      stderr = appendCapped(stderr, text);
      lineBuffer += text;
      const lines = lineBuffer.split(/\r?\n|\r/g);
      lineBuffer = lines.pop() ?? "";
      lines.forEach((line) => options.onLine?.(line));
    });
    child.once("close", (code) => {
      if (lineBuffer) options.onLine?.(lineBuffer);
      if (settled) return;
      if (code === 0) finish();
      else finish(new Error(classifyToolFailure(stderr)));
    });
  });
}

function appendCapped(current: string, next: string): string {
  const combined = current + next;
  return combined.length > 128_000 ? combined.slice(-128_000) : combined;
}

function classifyToolFailure(output: string): string {
  const value = output.toLowerCase();
  if (value.includes("sign in") || value.includes("login") || value.includes("cookies")) return "AUTH_REQUIRED";
  if (value.includes("unsupported url")) return "UNSUPPORTED_URL";
  if (value.includes("video unavailable") || value.includes("not available")) return "MEDIA_UNAVAILABLE";
  if (value.includes("file is larger than max-filesize")) return "FILE_TOO_LARGE";
  return "TOOL_FAILED";
}
