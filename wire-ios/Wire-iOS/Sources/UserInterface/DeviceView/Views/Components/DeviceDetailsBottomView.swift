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
import WireCommonComponents
import WireDesign

struct DeviceDetailsBottomView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    var showRemoveDeviceButton = true

    var fingerPrintInfoTextView: some View {
        Text(L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle)
            .font(FontSpec.mediumRegularFont.swiftUIFont)
            .padding([.leading, .trailing], ViewConstants.Padding.standard)
            .padding([.top, .bottom], ViewConstants.Padding.medium)
    }

    var resetSessionView: some View {
        HStack {
            Button {
                viewModel.resetSession()
            } label: {
                Text(L10n.Localizable.Profile.Devices.Detail.ResetSession.title)
                    .padding(.all, ViewConstants.Padding.standard)
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
                    .font(FontSpec.normalRegularFont.swiftUIFont.bold())
            }
            Spacer()
        }.background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
    }

    var resetSessionInfoView: some View {
        Text(L10n.Localizable.Self.Settings.DeviceDetails.ResetSession.subtitle)
            .font(FontSpec.mediumRegularFont.swiftUIFont)
            .padding([.leading, .trailing], ViewConstants.Padding.standard)
            .padding([.top, .bottom], ViewConstants.Padding.medium)
    }

    var removeDeviceView: some View {
        HStack {
            Button {
                Task {
                    await viewModel.removeDevice()
                }
            } label: {
                Text(L10n.Localizable.Self.Settings.AccountDetails.RemoveDevice.title)
                    .padding(.all, ViewConstants.Padding.standard)
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
                    .font(FontSpec.normalRegularFont.swiftUIFont.bold())
            }
            Spacer()
        }
        .background(Color(uiColor: SemanticColors.View.backgroundDefaultWhite))
    }

    var removeDeviceInfoView: some View {
        Text(L10n.Localizable.Self.Settings.DeviceDetails.RemoveDevice.subtitle)
            .font(.footnote)
            .padding([.leading, .trailing], ViewConstants.Padding.standard)
            .padding([.top, .bottom], ViewConstants.Padding.medium)
    }

    var body: some View {
        fingerPrintInfoTextView
        resetSessionView
        resetSessionInfoView
        if showRemoveDeviceButton {
            removeDeviceView
            removeDeviceInfoView
        }
    }
}
