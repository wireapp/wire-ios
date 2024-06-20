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

struct DeviceDetailsProteusView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @State var isVerified: Bool
    var shouldShowActivatedDate: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            CopyValueView(
                title: L10n.Localizable.Device.Details.Section.Proteus.id,
                value: viewModel.proteusID,
                isCopyEnabled: false,
                performCopy: nil
            )
            .padding(.all, ViewConstants.Padding.standard)

            if shouldShowActivatedDate {
                Divider()

                Text(L10n.Localizable.Device.Details.Section.Proteus.activated)
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textSectionHeader))
                    .font(FontSpec.mediumSemiboldFont.swiftUIFont)
                    .padding([.leading, .top], ViewConstants.Padding.standard)
                    .padding(.bottom, ViewConstants.Padding.small)

                Text(viewModel.addedDate)
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
                    .padding([.leading, .trailing, .bottom], ViewConstants.Padding.standard)
                    .font(FontSpec.normalRegularFont.swiftUIFont)
            }

            Divider()

            CopyValueView(
                title: L10n.Localizable.Device.Details.Section.Proteus.keyFingerprint,
                value: $viewModel.proteusKeyFingerprint.wrappedValue,
                isCopyEnabled: viewModel.isCopyEnabled,
                performCopy: viewModel.copyToClipboard
            )
            .padding(.all, ViewConstants.Padding.standard)

            if !viewModel.isSelfClient {
                Divider()

                Toggle(L10n.Localizable.Device.verified, isOn: $isVerified)
                    .font(FontSpec.headerSemiboldFont.swiftUIFont)
                    .padding(.all, ViewConstants.Padding.standard)
                    .onChange(of: isVerified) { value in
                        Task {
                            await viewModel.updateVerifiedStatus(value)
                        }
                    }
            }
        }
    }
}
