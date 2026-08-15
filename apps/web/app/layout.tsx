import type { Metadata } from "next";
import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://readydownloader.vercel.app"),
  title: "ReadyDownloader — 在线视频下载",
  description: "解析公开视频链接，选择画质并下载最高画质或 iPhone 兼容视频。",
  alternates: { canonical: "/" },
  openGraph: {
    title: "ReadyDownloader",
    description: "Bilingual video downloader for public media pages.",
    url: "/",
    siteName: "ReadyDownloader",
    type: "website"
  }
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
