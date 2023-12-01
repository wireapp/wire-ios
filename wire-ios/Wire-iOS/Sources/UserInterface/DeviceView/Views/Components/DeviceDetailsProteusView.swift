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
    @ObservedObject var viewModel: DeviceInfoViewModel
    @State var isVerfied: Bool

    var body: some View {
        VStack(alignment: .leading) {
            CopyValueView(
                title: L10n.Localizable.Device.Details.Section.Proteus.id,
                value: viewModel.proteusID,
                isCopyEnabled: false,
                performCopy: nil
            )
            .padding(.all, 16)
            Divider()
            Text(L10n.Localizable.Device.Details.Section.Proteus.activated)
                .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
                .font(UIFont.mediumSemiboldFont.swiftUIFont)
                .padding([.leading, .top], 16)
                .padding(.bottom, 4)
            Text(viewModel.addedDate)
                .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
                .padding([.leading, .trailing, .bottom], 16)
                .font(UIFont.normalRegularFont.swiftUIFont)
            Divider()
            CopyValueView(
                title: L10n.Localizable.Device.Details.Section.Proteus.keyfingerprint,
                value: $viewModel.proteusKeyFingerprint.wrappedValue,
                isCopyEnabled: viewModel.isCopyEnabled,
                performCopy: viewModel.copyToClipboard
            ).padding(.all, 16)
            if !viewModel.isSelfClient {
                Divider()
                Toggle(L10n.Localizable.Device.verified, isOn: $isVerfied)
                .font(UIFont.headerSemiBoldFont.swiftUIFont)
                .padding(.all, 16)
                .onChange(of: isVerfied) { value in
                    Task {
                        await self.viewModel.updateVerifiedStatus(value)
                    }
                }
            }
        }
    }
}
