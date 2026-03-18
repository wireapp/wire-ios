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
    var strokeColor: Color?
    
    private var color: Color {
        strokeColor ?? wireAccentColor.color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0
        
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
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
    @MainActor static func wireDriveAsset(strokeColor: Color? = nil) -> Self {
        Self(strokeColor: strokeColor)
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
