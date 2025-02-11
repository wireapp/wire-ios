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

class BundleClass {}

struct UploadVideoPreview: View {
    let duration: Duration
    let thumbnail: Image
    let onPlay: @Sendable () -> Void
    let onRemove: @Sendable () -> Void

    init(
        duration: Duration,
        thumbnail: Image,
        onPlay: @escaping @Sendable () -> Void,
        onRemove: @escaping @Sendable () -> Void
    ) {
        self.duration = duration
        self.thumbnail = thumbnail
        self.onPlay = onPlay
        self.onRemove = onRemove
    }

    var body: some View {
        LocalImagePreview(image: thumbnail)
            .deleteItemButton(onRemove: onRemove)
            .overlay(alignment: .center) {
                Button(action: {
                    onPlay()
                }, label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                        .somethingButtonStyle(padding: 3)
                })
                .foregroundStyle(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(duration.formatted())
                    .foregroundStyle(.white)
                    .padding(.trailing, 9)
                    .padding(.bottom, 6)
            }
    }
}

public struct UploadVideoPreview_Preview: View {
    let demoThumbnailName: String

    public init(demoThumbnailName: String) {
        self.demoThumbnailName = demoThumbnailName
    }

    public var body: some View {
        UploadVideoPreview(
            duration: Duration(secondsComponent: 142, attosecondsComponent: 0),
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
        UploadVideoPreview_Preview(demoThumbnailName: "demo-image")
            .frame(width: 200, height: 200)
            .background(.white)
    }
    .background(.black)
}
