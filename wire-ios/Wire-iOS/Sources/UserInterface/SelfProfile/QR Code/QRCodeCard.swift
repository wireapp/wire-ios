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
    @ObservedObject var viewModel: UserQRCodeViewModel

    var body: some View {
        VStack {
            Image(uiImage: viewModel.profileLinkQRCode)
                .interpolation(.none)
                .resizable()
                .frame(width: 250, height: 250)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            VStack(alignment: .center) {
                Text(viewModel.handle)
                    .font(.textStyle(.h2))
                    .foregroundColor(.black)
                Text(viewModel.profileLink)
                    .font(.textStyle(.subline1))
                    .foregroundColor(.black)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom, 21)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}
