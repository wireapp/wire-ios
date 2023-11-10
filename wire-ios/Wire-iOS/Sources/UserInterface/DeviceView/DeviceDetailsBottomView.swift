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
        Text("self.settings.device_details.fingerprint.subtitle".localized)
            .font(.footnote)
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.actionsHandler.resetSession()
                }
            } label: {
                Text("profile.devices.detail.reset_session.title".localized)
                    .padding(.all, 16)
                    .foregroundColor(.black)
                    .font(UIFont.normalRegularFont.swiftUIfont.bold())
            }
            Spacer()
        }.background(Color.white)
        Text("self.settings.device_details.reset_session.subtitle".localized).font(.footnote).padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.actionsHandler.removeDevice()
                }
            } label: {
                Text("self.settings.account_details.remove_device.title".localized)
                    .padding(.all, 16)
                    .foregroundColor(.black).font(UIFont.normalRegularFont.swiftUIfont.bold())
            }
            Spacer()
        }.background(Color.white)
        Text("self.settings.device_details.remove_device.subtitle".localized)
            .font(.footnote)
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
    }
}
