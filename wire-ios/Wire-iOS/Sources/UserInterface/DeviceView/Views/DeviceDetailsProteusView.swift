//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

struct DeviceDetailsProteusView: View {
    @Binding var viewModel: DeviceInfoViewModel
    var body: some View {
            VStack(alignment: .leading) {
                CopyValueView(title: L10n.Localizable.Device.Proteus.id, value: viewModel.proteusID, performCopy: { value in
                    viewModel.actionsHandler.copyToClipboard(value)
                })
                    .padding([.leading, .trailing], 16)
                    .padding(.top, 8.0)
                Divider()
                Text(L10n.Localizable.Device.Details.Activated.title)
                    .font(UIFont.mediumSemiboldFont.swiftUIfont)
                    .padding(.leading, 16)
                Text(viewModel.addedDate)
                    .padding(.leading, 16)
                    .font(UIFont.normalRegularFont.swiftUIfont)
                Divider()
                CopyValueView(
                    title: L10n.Localizable.Device.Details.Proteus.Key.fingerprint,
                    value: viewModel.deviceKeyFingerprint,
                    performCopy: { value in
                            viewModel.actionsHandler.copyToClipboard(value)
                        }
                ).padding([.leading, .trailing], 16)
                Divider()
                Toggle(L10n.Localizable.Device.verified, isOn: $viewModel.isProteusVerificationEnabled).font(.headline).padding([.leading, .trailing, .bottom], 16)
            }.background(Color.white)
    }
}
