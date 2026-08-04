import AppKit
import SwiftUI

enum DownloaderTheme {
    static var canvas: Color {
        adaptive(
            light: NSColor(red: 0.945, green: 0.952, blue: 0.958, alpha: 1),
            dark: NSColor(red: 0.065, green: 0.073, blue: 0.069, alpha: 1)
        )
    }

    static var panel: Color {
        adaptive(
            light: NSColor(red: 0.985, green: 0.987, blue: 0.990, alpha: 1),
            dark: NSColor(red: 0.105, green: 0.118, blue: 0.110, alpha: 1)
        )
    }

    static var field: Color {
        adaptive(
            light: NSColor(red: 0.958, green: 0.965, blue: 0.970, alpha: 1),
            dark: NSColor(red: 0.145, green: 0.158, blue: 0.150, alpha: 1)
        )
    }

    static var ink: Color { Color(nsColor: .labelColor) }
    static var muted: Color { Color(nsColor: .secondaryLabelColor) }
    static var stroke: Color { Color(nsColor: .separatorColor).opacity(0.65) }
    static var accent: Color {
        adaptive(
            light: NSColor(red: 0.20, green: 0.43, blue: 0.24, alpha: 1),
            dark: NSColor(red: 0.36, green: 0.66, blue: 0.38, alpha: 1)
        )
    }
    static var accentSoft: Color { accent.opacity(0.13) }
    static let info = Color(red: 0.439, green: 0.663, blue: 0.855)
    static let danger = Color(red: 0.950, green: 0.376, blue: 0.329)

    static func color(for kind: DownloadStatusKind) -> Color {
        switch kind {
        case .neutral: muted
        case .progress: info
        case .success: accent
        case .failure: danger
        }
    }

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

struct DownloaderPanel<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DownloaderTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(DownloaderTheme.muted)
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DownloaderTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DownloaderTheme.stroke, lineWidth: 0.5)
        }
    }
}

struct DownloaderMark: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(DownloaderTheme.accentSoft)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .stroke(DownloaderTheme.accent.opacity(0.28), lineWidth: 1)
                }
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(DownloaderTheme.accent)
        }
        .frame(width: size, height: size)
    }
}

struct DownloaderStatusView: View {
    let kind: DownloadStatusKind
    let title: String
    let detail: String
    let isWorking: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Circle()
                        .fill(DownloaderTheme.color(for: kind))
                        .frame(width: 9, height: 9)
                        .padding(.top, 4)
                }
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(DownloaderTheme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(DownloaderTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(DownloaderTheme.field, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DownloaderTheme.color(for: kind).opacity(0.22), lineWidth: 1)
        }
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(DownloaderTheme.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
