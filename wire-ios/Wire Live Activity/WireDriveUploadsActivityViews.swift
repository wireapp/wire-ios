//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import SwiftUI
import WireDesign
import WireDriveUploadsActivity
import WireFoundation

// MARK: - Lock screen and banner

struct WireDriveUploadsBannerView: View {

    let state: WireDriveUploadsActivityState

    private var presentation: WireDriveUploadsActivityPresentation {
        .init(state)
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 14) {
                WireDriveUploadsTexts(presentation: presentation)

                Spacer(minLength: 0)

                if presentation.isFinished {
                    WireDriveUploadsStatusIcon(phase: state.phase)
                }

                Image("WireLogo")
                    .accessibilityHidden(true)
            }

            if !presentation.isFinished {
                ProgressView(value: state.progress)
                    .progressViewStyle(WireDriveUploadsProgressBarStyle())
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 29)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pieces

struct WireDriveUploadsTexts: View {

    let presentation: WireDriveUploadsActivityPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(presentation.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(ColorTheme.Backgrounds.onBackground.onDarkSurface)

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ColorTheme.Base.secondaryText.onDarkSurface)
        }
    }

    /// The subtitle, with what failed in red.
    private var subtitle: AttributedString {
        guard let failureText = presentation.failureText else {
            return AttributedString(presentation.subtitle)
        }

        var failure = AttributedString(failureText)
        failure.foregroundColor = ColorTheme.Base.error.onDarkSurface

        return AttributedString(presentation.progressSubtitle + WireDriveUploadsActivityPresentation.separator)
            + failure
    }
}

/// The result of finished uploads: all went well, or at least one failed.
struct WireDriveUploadsStatusIcon: View {

    static let defaultSize: CGFloat = 24

    let phase: WireDriveUploadsActivityState.Phase
    var size: CGFloat = Self.defaultSize

    var body: some View {
        switch phase {
        case .completed:
            Image(systemName: "checkmark.circle")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(ColorTheme.Buttons.Primary.enabled.color)
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(ColorTheme.Base.error.onDarkSurface)
        case .uploading, .uploadingWithFailures:
            EmptyView()
        }
    }
}

/// A thin bar, as in the design, whose track and fill the system progress view can't be coloured to match.
struct WireDriveUploadsProgressBarStyle: ProgressViewStyle {

    func makeBody(configuration: Configuration) -> some View {
        let fraction = min(max(configuration.fractionCompleted ?? 0, 0), 1)

        RoundedRectangle(cornerRadius: 3)
            .fill(BaseColorPalette.Grays.gray80.onDarkSurface)
            .frame(height: 5)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ColorTheme.Base.primary(.blue).onDarkSurface)
                        .frame(width: proxy.size.width * fraction)
                }
            }
    }
}

// MARK: - Dynamic Island

/// The leading side of the compact island, and the minimal one: progress while uploading, the result once
/// finished.
struct WireDriveUploadsIslandIndicator: View {

    /// The side of the square every indicator is drawn in, so that they all look the same size.
    static let size: CGFloat = 20

    let state: WireDriveUploadsActivityState

    var body: some View {
        switch state.phase {
        case .uploading, .uploadingWithFailures:
            WireDriveUploadsProgressRing(progress: state.progress)
                .frame(width: Self.size, height: Self.size)
        case .completed, .failed:
            WireDriveUploadsStatusIcon(phase: state.phase, size: Self.size)
        }
    }
}

/// A ring that fills up as the uploads progress. Unlike the system progress view, it can be given a size.
struct WireDriveUploadsProgressRing: View {

    let progress: Double

    private let lineWidth: CGFloat = 2.5

    var body: some View {
        ZStack {
            Circle()
                .stroke(BaseColorPalette.Grays.gray80.onDarkSurface, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    ColorTheme.Base.primary(.blue).onDarkSurface,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
        .accessibilityHidden(true)
    }
}

struct WireDriveUploadsIslandCompactText: View {

    let state: WireDriveUploadsActivityState

    var body: some View {
        Text(WireDriveUploadsActivityPresentation(state).compactText)
            .font(.subheadline)
            .foregroundStyle(
                ColorTheme.Backgrounds.onBackground.onDarkSurface
            )
            .monospacedDigit()
    }
}
