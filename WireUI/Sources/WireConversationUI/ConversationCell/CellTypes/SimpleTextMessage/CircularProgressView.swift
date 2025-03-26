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

// Custom Shape that draws a pie-wedge for the progress.
struct ProgressArc: Shape {
    /// Progress value between 0.0 and 1.0.
    var progress: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Start at the top (i.e. -90°)
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + Double(progress) * 360)

        // Move to center and draw the arc, then close the path to form a wedge.
        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        path.closeSubpath()
        return path
    }

}

struct CircularProgressView: View {
    /// A value between 0.0 and 1.0 representing the progress.
    var progress: CGFloat

    var body: some View {
        ZStack {
            // Background circle with fill and stroke.
            Circle()
                .fill(Color.gray.opacity(0.3))

            // Filled progress arc
            ProgressArc(progress: progress)
                .fill(Color.red)
                .animation(.linear, value: progress)
                .overlay(
                    Circle()
                        .stroke(Color.red, lineWidth: 15)
                )
        }
    }
}

struct ContentView: View {
    @State private var progressValue: CGFloat = 0.7  // 70% progress

    var body: some View {
        CircularProgressView(progress: progressValue)
            .frame(width: 150, height: 150)
    }
}

#Preview {
    ContentView()
}
