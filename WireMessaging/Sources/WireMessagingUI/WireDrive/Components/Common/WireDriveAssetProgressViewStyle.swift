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

/// A custom circular progress view style (a progress bar) for upload & download of assets.
struct WireDriveAssetProgressViewStyle: ProgressViewStyle {
    @Environment(\.wireAccentColor) private var wireAccentColor
    @ScaledMetric private var lineWidth: CGFloat = 2
    
    /// The color of the empty circle in the background. Defaults to the user accent color with transparency if `nil`.
    var strokeColor: Color?
    
    /// The color of the progress circle in the foreground. Defaults to the user accent color if `nil`.
    var progressStrokeColor: Color?

    private var color: Color {
        strokeColor ?? wireAccentColor.color.opacity(0.2)
    }
    
    private var progressColor: Color {
        progressStrokeColor ?? wireAccentColor.color
    }

    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0

        ZStack {
            Circle()
                .stroke(color, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

extension ProgressViewStyle where Self == WireDriveAssetProgressViewStyle {
    /// - Parameters:
    ///   - strokeColor: The color of the empty circle in the background. Defaults to the user accent color with transparency if `nil`.
    ///   - progressStrokeColor: The color of the progress circle in the foreground. Defaults to the user accent color if `nil`.
    @MainActor
    static func wireDriveAsset(strokeColor: Color? = nil, progressStrokeColor: Color? = nil) -> Self {
        Self(strokeColor: strokeColor, progressStrokeColor: progressStrokeColor)
    }
}

#Preview {
    @Previewable @ScaledMetric var size: CGFloat = 40

    VStack(spacing: 16) {
        Group {
            ProgressView(value: 0)
            ProgressView(value: 0.3)
            ProgressView(value: 0.5)
            ProgressView(value: 0.9)
            ProgressView(value: 1)
            ProgressView(value: 0.7)
                .progressViewStyle(.wireDriveAsset(strokeColor: .orange))
        }
        .frame(width: size, height: size)
    }
    .progressViewStyle(.wireDriveAsset())
}
