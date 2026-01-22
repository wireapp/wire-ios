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

struct UploadAudioPreview: View {
    let duration: Duration
    @Binding var isPlaying: Bool
    @Binding var progress: Double

    let samples: [Double]

    let durationFormatPattern: Duration.TimeFormatStyle.Pattern

    init(
        duration: Duration,
        isPlaying: Binding<Bool>,
        progress: Binding<Double>,
        samples: [Double]
    ) {
        self.duration = duration
        self._isPlaying = isPlaying
        self._progress = progress

        self.samples = samples

        self.durationFormatPattern = duration.adaptativeFormatPattern
    }

    var body: some View {
        VStack {
            HStack(spacing: 7) {
                AudioPlayerPlaybackButton(
                    isPlaying: isPlaying,
                    onTap: { isPlaying.toggle() }
                )
                ProgressView(value: progress)
                    .progressViewStyle(WaveFormProgressViewStyle(onDrag: { updatedProgress in
                        isPlaying = false
                        print("Updated progress: \(updatedProgress)")
                        progress = updatedProgress
                    }, onDragEnded: {
                        isPlaying = true
                    }, samples: samples))
            }
            .frame(height: 40)

            HStack {
                Spacer()
                    .frame(width: 47)
                Text((duration * progress).formatted(.time(pattern: durationFormatPattern)))
                Spacer()
                Text(duration.formatted(.time(pattern: durationFormatPattern)))
            }
        }
    }
}

private struct AdaptiveDurationFormatStyle: FormatStyle {
    typealias FormatInput = Duration
    typealias FormatOutput = String

    func format(_ value: Duration) -> String {
        value.formatted(.time(pattern: value.adaptativeFormatPattern))
    }
}

private extension FormatStyle where Self == Duration.TimeFormatStyle {
    static var adaptive: AdaptiveDurationFormatStyle {
        AdaptiveDurationFormatStyle()
    }
}

private extension Duration {
    var adaptativeFormatPattern: Duration.TimeFormatStyle.Pattern {
        if components.seconds > 3600 {
            .hourMinuteSecond(padHourToLength: 2)
        } else {
            .minuteSecond(padMinuteToLength: 2)
        }
    }
}

#Preview {
    VStack {
        UploadAudioPreview_Preview()
            .frame(width: 350, height: 200)
            .padding()
            .background(.white)
    }
    .background(.black)
}
