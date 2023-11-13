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

struct DeviceDetailsE2EIdentityCertificateView: View {
    @Binding var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPreseneted: Bool
    var body: some View {
        Text(L10n.Localizable.Device.Details.E2e.Identity.certificate).font(UIFont.normalSemiboldFont.swiftUIfont).multilineTextAlignment(.leading)
            .padding([.top, .bottom], 16)
        Text(L10n.Localizable.Device.Details.status).font(UIFont.mediumSemiboldFont.swiftUIfont).foregroundColor(.gray).multilineTextAlignment(.leading)
        HStack {
            switch viewModel.e2eIdentityCertificate.status {
            case .notActivated:
                Text(viewModel.e2eIdentityCertificate.status.titleForStatus()).foregroundColor(.customRed).font(.subheadline).font(UIFont.normalMediumFont.swiftUIfont)
                Image(.certificateExpired)
            case .revoked:
                Text(viewModel.e2eIdentityCertificate.status.titleForStatus()).foregroundColor(.customRed).font(.subheadline).font(UIFont.normalMediumFont.swiftUIfont)
                Image(.certificateRevoked)
            case .expired:
                Text(viewModel.e2eIdentityCertificate.status.titleForStatus()).foregroundColor(.customRed).font(.subheadline).font(UIFont.normalMediumFont.swiftUIfont)
                Image(.certificateExpired)
            case .valid:
                Text(viewModel.e2eIdentityCertificate.status.titleForStatus()).foregroundColor(.customGreen).font(.subheadline).font(UIFont.normalMediumFont.swiftUIfont)
                Image(.certificateValid)
            case .none:
                Text(viewModel.e2eIdentityCertificate.status.titleForStatus()).foregroundColor(.black).font(UIFont.normalMediumFont.swiftUIfont)
                Image(asset: .init(name: ""))
            }
            Spacer()
        }
        if !viewModel.e2eIdentityCertificate.serialNumber.isEmpty {
            Text(L10n.Localizable.Device.Details.Serial.number)
                .font(UIFont.smallSemiboldFont.swiftUIfont)
                .foregroundColor(.gray).padding(.top, 8)
            Text(viewModel.e2eIdentityCertificate.serialNumber)
        }
    }
}
