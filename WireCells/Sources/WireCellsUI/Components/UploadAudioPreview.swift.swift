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

struct UploadAudioPreview: View {

    let duration: String
    let onPlay: @Sendable () -> Void
    let onRemove: @Sendable () -> Void

    init(
        duration: Duration,
        onPlay: @Sendable @escaping () -> Void,
        onRemove: @Sendable @escaping () -> Void
    ) {
        self.onPlay = onPlay
        self.onRemove = onRemove

        self.duration = duration.components.seconds > 3600
            ? duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
            : duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }

    var body: some View {
        EmptyView()
    }
}

public struct UploadAudioPreview_Preview: View {
    public var body: some View {
        UploadAudioPreview(
            duration: Duration(secondsComponent: 13681, attosecondsComponent: 0),
            onPlay: { },
            onRemove: { }
        )
    }

}

#Preview {
    VStack {
        UploadAudioPreview_Preview()
            .frame(width: 350, height: 200)
            .background(.white)
    }
    .background(.black)
}
