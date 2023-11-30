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
import WireCommonComponents

struct DeviceView: View {
    var viewModel: DeviceInfoViewModel
    
    var titleView: some View {
        HStack {
            Text(viewModel.title.clippedValue())
                .font(UIFont.headerSemiBoldFont.swiftUIFont)
                .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
            if let e2eIdentityCertificateStatusImage = viewModel.certificateStatus.imageForStatus() {
                e2eIdentityCertificateStatusImage
            }
            if viewModel.isProteusVerificationEnabled {
                Image(.certificateVerified)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            titleView
            if !viewModel.proteusID.isEmpty {
                Text("\(L10n.Localizable.Device.Details.Section.Proteus.id): \(viewModel.proteusID)")
                    .font(UIFont.mediumRegular.swiftUIFont)
                    .foregroundColor(SemanticColors.Label.textSectionHeader.swiftUIColor)
            }
        }
    }
}

private extension String {
    func clippedValue() -> String {
        let offsetValue = 25
        if self.count > offsetValue {
            return String(
                self[...self.index(
                    self.startIndex,
                    offsetBy: offsetValue
                )]
            ) + "..."
        } else {
            return self
        }
    }
}
