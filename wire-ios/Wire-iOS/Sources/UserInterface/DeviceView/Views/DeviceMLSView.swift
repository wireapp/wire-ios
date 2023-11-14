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

struct DeviceMLSView: View {
    @Binding var viewModel: DeviceInfoViewModel
    var body: some View {
        VStack {
            CopyValueView(
                title: L10n.Localizable.Device.Mls.thumbprint,
                value: viewModel.mlsThumbprint,
                performCopy: { value in
                   viewModel.actionsHandler.copyToClipboard(value)
               }
            ).frame(maxHeight: .infinity)
        }
    }
}

#Preview {
    DeviceMLSView(viewModel:
            .constant(DeviceInfoViewModel(
                    udid: "123g4",
                    title: "Device 4",
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
""", certificate: .random(length: 1000),
                            exipirationDate: .now + .fourWeeks))))
}
