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

/// A custom progress view style (a progress bar) for upload & download of assets.
struct AssetProgressStyle: ProgressViewStyle {

    enum Constants {
        static let height: Double = 3
    }

    let fillColor: Color

    func makeBody(configuration: Configuration) -> some View {
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
    }
}
