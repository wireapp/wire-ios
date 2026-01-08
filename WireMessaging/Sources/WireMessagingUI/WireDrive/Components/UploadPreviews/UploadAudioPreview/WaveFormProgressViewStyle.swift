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

struct WaveFormProgressViewStyle: ProgressViewStyle {
    private enum Constants {
        static let sampleBarWidth: CGFloat = 2
        static let sampleBarSpacing: CGFloat = 1
        static let seekBarPadding: CGFloat = 1.5
        static let seekBarWidth: CGFloat = 3
    }

    let onDrag: (_ updatedProgress: Double) -> Void
    let onDragEnded: () -> Void
    @State var progressAtGestureStart: Double?
    let samplesCount: Int
    let samples: [Double]

    init(
        onDrag: @escaping (_ updatedProgress: Double) -> Void,
        onDragEnded: @escaping () -> Void,
        samples: [Double]
    ) {
        self.onDrag = onDrag
        self.onDragEnded = onDragEnded
        self.samples = samples
        self.samplesCount = samples.count
    }

    /// Resample the input samples to a target count.
    /// Here we group the original samples into chunks and take the maximum value in each chunk.
    static func resample(samples: [Double], to targetCount: Int) -> [Double] {
        guard !samples.isEmpty, targetCount > 0 else { return [] }
        // If there are fewer samples than targetCount, return what you have.
        if samples.count <= targetCount {
            return samples
        }

        let step = Double(samples.count) / Double(targetCount)
        return (0 ..< targetCount).map { i in
            let start = Int(Double(i) * step)
            let end = Int(Double(i + 1) * step)
            let chunk = samples[start ..< min(end, samples.count)]
            // Instead of taking the chunk's average, we could take the chunk's max.
//            return chunk.max() ?? 0
            let sum = chunk.reduce(0.0, +)
            return sum / Double(chunk.count)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            // Calculate how many bars can fit in the available width.
            // Note: We include spacing in the calculation.
            let targetCount = Int(geometry.size.width / (Constants.sampleBarWidth + Constants.sampleBarSpacing))

            // Resample our samples to match the number of bars.
            let resampledSamples = Self.resample(samples: samples, to: targetCount)

            // Determine the current progress (between 0 and 1)
            let progressFraction = configuration.fractionCompleted ?? 0.0

            HStack(spacing: Constants.sampleBarSpacing) {
                ForEach(Array(resampledSamples.enumerated()), id: \.offset) { index, value in
                    // Calculate the bar’s height relative to the available height.
                    // Assumes 'value' is normalized between 0 and 1.
                    let barHeight = geometry.size.height * CGFloat(value)

                    // Determine if the bar has been played by comparing its relative position to the progress fraction.
                    let barPositionFraction = Double(index) / Double(resampledSamples.count)
                    let isPlayed = barPositionFraction < progressFraction

                    RoundedRectangle(cornerRadius: Constants.sampleBarWidth / 2, style: .continuous)
                        .fill(isPlayed ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: Constants.sampleBarWidth, height: barHeight)
                }
            }.overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: Constants.seekBarWidth / 2, style: .continuous)
                    .fill(Color.blue)
                    .frame(width: Constants.seekBarWidth, height: geometry.size.height)
                    .padding(Constants.seekBarPadding)
                    .background(.white)
                    .offset(
                        x: geometry.size
                            .width * progressFraction - (Constants.seekBarPadding + Constants.seekBarWidth / 2)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                // DragGesture.translation is the total translation from the _start_ of the drag gesture
                                // We therefore must store the progress at the start of the drag gesture, else we'd
                                // accumulate changes over time.
                                if progressAtGestureStart == nil {
                                    progressAtGestureStart = progressFraction
                                }
                                let updatedProgress = progressAtGestureStart! + gesture.translation.width / geometry
                                    .size.width
                                onDrag(max(0, min(1, updatedProgress)))
                            }
                            .onEnded { _ in
                                progressAtGestureStart = nil
                                onDragEnded()
                            }
                    )
            }
        }
    }
}
