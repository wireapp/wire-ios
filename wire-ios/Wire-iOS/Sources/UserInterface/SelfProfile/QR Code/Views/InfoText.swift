//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct InfoText: View {

    var body: some View {
        Text(L10n.Localizable.Qrcode.shareMessage)
            .font(.textStyle(.body1))
            .multilineTextAlignment(.center)
            .foregroundColor(Color.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

}

// MARK: - Preview

#Preview {
    InfoText()
}
