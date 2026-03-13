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
        static let lineWidth: CGFloat = 2
        static let size: CGFloat = 12
    }
    
    let fillColor: Color
    let trackColor: Color = .gray.opacity(0.2)
    
    @ScaledMetric private var scale: CGFloat = 1
    
    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0
        
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: Constants.lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    fillColor,
                    style: StrokeStyle(
                        lineWidth: Constants.lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .frame(width: Constants.size * scale, height: Constants.size * scale)
    }
}
