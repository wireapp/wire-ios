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
import WireDesign

/// A wire cells specific view that displays an warning icon within a circle.

struct WireDriveAttachmentPreviewErrorCircle: View {

    enum Constants {
        static let backgroundColor = ColorTheme.Buttons.Secondary.enabled.color
        static let borderColor = ColorTheme.Buttons.Secondary.enabledOutline.color
        static let iconColor = ColorTheme.Base.error.color
    }

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(Constants.borderColor)
                .frame(width: 26, height: 26)

            Circle()
                .foregroundStyle(Constants.backgroundColor)
                .frame(width: 24, height: 24)

            Image(systemName: "exclamationmark.triangle")
                .fontWeight(.semibold)
                .font(.system(size: 12))
                .foregroundColor(Constants.iconColor)
                .padding(.bottom, 2)
        }
    }

}

#Preview {
    WireCellsAttachmentPreviewErrorCircle()
}
