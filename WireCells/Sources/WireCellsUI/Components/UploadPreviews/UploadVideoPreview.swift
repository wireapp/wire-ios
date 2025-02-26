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

public import SwiftUI

struct UploadVideoPreview: View {
    private enum Constants {
        static let playButtonFontSize: CGFloat = 48
        static let playButtonPadding: CGFloat = 3
        static let durationLabelTrailingPadding: CGFloat = 9
        static let durationLabelBottomPadding: CGFloat = 6
    }

    let duration: String
    let thumbnail: Image
    let onPlay: @Sendable () -> Void
    let onRemove: @Sendable () -> Void

    init(
        duration: Duration,
        thumbnail: Image,
        onPlay: @escaping @Sendable () -> Void,
        onRemove: @escaping @Sendable () -> Void
    ) {
        self.thumbnail = thumbnail
        self.onPlay = onPlay
        self.onRemove = onRemove

        self.duration = duration.components.seconds > 3600
            ? duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
            : duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }

    var body: some View {
        LocalImagePreview(image: thumbnail)
            .deleteItemButton(onRemove: onRemove)
            .overlay(alignment: .center) {
                Button(action: {
                    onPlay()
                }, label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: Constants.playButtonFontSize))
                })
                .foregroundStyle(.white)
                .buttonStyle(CircularIconButtonStyle(padding: Constants.playButtonPadding))
            }
            .overlay(alignment: .bottomTrailing) {
                Text(duration)
                    .foregroundStyle(.white)
                    .padding(.trailing, Constants.durationLabelTrailingPadding)
                    .padding(.bottom, Constants.durationLabelBottomPadding)
            }
    }
}

public struct UploadVideoPreview_Preview: View {
    let demoThumbnailName: String
    let duration: Duration

    public init(
        demoThumbnailName: String,
        duration: Duration = Duration(
            secondsComponent: 142,
            attosecondsComponent: 0
        )
    ) {
        self.demoThumbnailName = demoThumbnailName
        self.duration = duration
    }

    public var body: some View {
        UploadVideoPreview(
            duration: duration,
            thumbnail: Image(demoThumbnailName, bundle: .module),
            onPlay: {
                print("Play")
            },
            onRemove: {
                print("remove")
            }
        )
    }

}

#Preview {
    VStack {
        UploadVideoPreview_Preview(demoThumbnailName: "rectangular-placeholder")
            .frame(width: 200, height: 200)
            .background(.white)
    }
    .background(.black)
}
