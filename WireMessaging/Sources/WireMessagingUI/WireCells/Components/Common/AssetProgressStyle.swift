//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A custom progress view style (a progress bar) for upload & download of assets.
struct AssetProgressStyle: ProgressViewStyle {

    enum Constants {
        static let height: Double = 3
    }

    enum Variant {
        case linear
        case circular
    }

    let variant: Variant
    let fillColor: Color

    func makeBody(configuration: Configuration) -> some View {
        switch variant {
        case .linear:
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let progress = Double(configuration.fractionCompleted ?? 0)
                let barWidth = totalWidth * progress

                let cornerRadius = progress < 1 ? Constants.height / 2 : 0
                UnevenRoundedRectangle(bottomTrailingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                    .fill(fillColor)
                    .frame(width: barWidth, height: Constants.height)
            }
            .frame(height: Constants.height)
        case .circular:
            let progress = Double(configuration.fractionCompleted ?? 0)
            CircularProgressView(progress: progress, color: fillColor)
                .frame(width: 20, height: 20)
        }
    }

    private struct CircularProgressView: View {
        let progress: Double
        let color: Color

        var body: some View {
            ZStack {
                Circle()
                    .stroke(
                        color.opacity(0.5),
                        lineWidth: 2
                    )
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)

            }
        }
    }
}
