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

struct DeviceView: View {
    var viewModel: DeviceInfoViewModel
    var body: some View {
        VStack {
        HStack {
            Text(viewModel.title)
            switch viewModel.e2eIdentityCertificate.status {
            case .notActivated:
                Image(.certificateExpired)
            case .revoked:
                Image(.certificateRevoked)
            case .expired:
                Image(.certificateExpired)
            case .valid:
                Image(.certificateValid)
            case .none:
                Image(asset: .init(name: ""))
            }
            if viewModel.isProteusVerificationEnabled {
                Image(.verified)
            }
            Spacer()
        }
            HStack {
                Text("MLS Thumbprint: \(viewModel.mlsThumbprint)").font(.subheadline).foregroundColor(.gray).padding(.top).lineLimit(1)
                Spacer()
            }
            HStack {
                Text("Proteus ID: \(viewModel.proteusID)").multilineTextAlignment(.leading).font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
        }
    }
}

#Preview {
    DeviceView(viewModel:
                DeviceInfoViewModel(
                    udid: "123g4",
                    title: "Device 4",
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
""")))
}
