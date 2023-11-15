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

struct DeviceDetailsBottomView: View {
    @Binding var viewModel: DeviceInfoViewModel
    var body: some View {
        Text(L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle)
            .font(.footnote)
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.actionsHandler.resetSession()
                }
            } label: {
                Text(L10n.Localizable.Profile.Devices.Detail.ResetSession.title)
                    .padding(.all, 16)
                    .foregroundColor(.black)
                    .font(UIFont.normalRegularFont.swiftUIfont.bold())
            }
            Spacer()
        }.background(Color.white)
        Text(L10n.Localizable.Self.Settings.DeviceDetails.ResetSession.subtitle).font(.footnote).padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.actionsHandler.removeDevice()
                }
            } label: {
                Text(L10n.Localizable.Self.Settings.AccountDetails.RemoveDevice.title)
                    .padding(.all, 16)
                    .foregroundColor(.black).font(UIFont.normalRegularFont.swiftUIfont.bold())
            }
            Spacer()
        }.background(Color.white)
        Text(L10n.Localizable.Self.Settings.DeviceDetails.RemoveDevice.subtitle)
            .font(.footnote)
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
    }
}
