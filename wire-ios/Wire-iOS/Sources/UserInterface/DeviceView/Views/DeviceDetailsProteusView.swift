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
        VStack(
            alignment: .leading
        ) {
            CopyValueView(
                title: L10n.Localizable.Device.Proteus.id,
                value: viewModel.proteusID,
                isCopyEnabled: viewModel.isCopyEnabled,
                performCopy: {
                    value in
                    viewModel.actionsHandler.copyToClipboard(
                        value
                    )
                })
            .padding(
                [
                    .leading,
                    .trailing
                ],
                16
            )
            .padding(
                .top,
                8.0
            )
            Divider()
            Text(
                L10n.Localizable.Device.Details.Activated.title
            )
            .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
            .font(
                UIFont.mediumSemiboldFont.swiftUIfont
            )
            .padding(
                .leading,
                16
            )
            Text(
                viewModel.addedDate
            )
            .foregroundColor(SemanticColors.Label.textDefault.swiftUIColor)
            .padding(
                .leading,
                16
            )
            .font(
                UIFont.normalRegularFont.swiftUIfont
            )
            Divider()
            CopyValueView(
                title: L10n.Localizable.Device.Details.Proteus.Key.fingerprint,
                value: viewModel.deviceKeyFingerprint,
                isCopyEnabled: viewModel.isCopyEnabled,
                performCopy: {
                    value in
                    viewModel.actionsHandler.copyToClipboard(
                        value
                    )
                }
            ).padding(
                [
                    .leading,
                    .trailing
                ],
                16
            )
            Divider()
            Toggle(
                L10n.Localizable.Device.verified,
                isOn: $viewModel.isProteusVerificationEnabled
            ).font(
                UIFont.headerSemiBoldFont.swiftUIfont
            ).padding(
                [
                    .leading,
                    .trailing,
                    .bottom
                ],
                16
            ).onChange(
                of: viewModel.isProteusVerificationEnabled
            ) { value in
                viewModel.actionsHandler.setVerified(
                    value
                )
            }
        }.background(
            SemanticColors.View.backgroundDefault.swiftUIColor
        )
    }
}

#Preview {
    DeviceDetailsProteusView(
        viewModel:
                .constant(
                    DeviceInfoViewModel(
                        udid: "123g4",
                        title: "Device 4",
                        addedDate: "21/10/2023",
                        mlsThumbprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
""",
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
                                status: .notActivated,
                                serialNumber:
"""
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
    )
}
