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

struct QRCodeCard: View {

    // MARK: - Properties

    let profileLinkQRCode: UIImage
    let handle: String
    let profileLink: String

    // MARK: - View

    var body: some View {
        VStack {
            Image(uiImage: profileLinkQRCode)
                .resizable()
                .frame(width: 250, height: 250)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            VStack(alignment: .center) {
                Text(handle)
                    .font(.textStyle(.h2))
                    .foregroundColor(.black)
                Text(profileLink)
                    .font(.textStyle(.subline1))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom, 21)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}
