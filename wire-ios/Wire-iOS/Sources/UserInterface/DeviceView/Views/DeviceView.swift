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
            Text(
                viewModel.title.clippedValue()
            )
            .font(
                UIFont.headerSemiBoldFont.swiftUIfont
            )
            .foregroundColor(
                .black
            )
            if let e2eIdentityCertificateStatusImage = viewModel.e2eIdentityCertificate.status.imageForStatus() {
                e2eIdentityCertificateStatusImage
            }
            if viewModel.isProteusVerificationEnabled {
                Image(
                    .verified
                )
            }
        }
    }
    var body: some View {
        VStack(
            alignment: .leading
        ) {
            titleView
            if !viewModel.mlsThumbprint.isEmpty {
                Text(
                    "\(L10n.Localizable.Device.Mls.thumbprint): \(viewModel.mlsThumbprint)"
                ).font(
                    UIFont.mediumRegular.swiftUIfont
                ).foregroundColor(
                    .gray
                ).lineLimit(
                    1
                )
            }
            if !viewModel.proteusID.isEmpty {
                Text(
                    "\(L10n.Localizable.Device.Proteus.id): \(viewModel.proteusID)"
                ).font(
                    UIFont.mediumRegular.swiftUIfont
                ).foregroundColor(
                    .gray
                )
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

#Preview {
    DeviceView(
        viewModel:
            DeviceInfoViewModel(
                udid: "123g4",
                title: "Devidfdfgdfgdfgdfgfddfdfgdfdgfdgdgdfgdfgdfgdfgdfgdfgdfdgfdfgdgdgdfgdce 4",
                addedDate: "21/10/2023",
                mlsThumbprint: "skfjnskjdffnskjn",
                deviceKeyFingerprint:
"""
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""",
                proteusID: "skjdabfnkscjka",
                isProteusVerificationEnabled: false,
                e2eIdentityCertificate:
                    E2EIdentityCertificate(
                        status: .none,
                        serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""",

                        certificate: .random(
                            length: 1000
                        ),
                            exipirationDate: .now + .fourWeeks
                        )
                )
    )
}
