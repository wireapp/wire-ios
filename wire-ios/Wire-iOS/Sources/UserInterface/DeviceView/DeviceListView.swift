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

struct DeviceListView: View {
    @State var viewModel: DevicesViewModel
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List {
                    Section(header: Text("device.current.title".localized)) {
                        NavigationLink(destination: DeviceDetailsView(viewModel: viewModel.currentDevice, isCertificateViewPresented: false)) {
                            DeviceView(viewModel: viewModel.currentDevice)
                        }
                    }
                    if !viewModel.otherDevices.isEmpty {
                        Section(header: Text("device.active.title".localized)) {
                            ForEach(viewModel.otherDevices) { deviceViewModel in
                                NavigationLink(destination: DeviceDetailsView(viewModel: deviceViewModel, isCertificateViewPresented: false)) {
                                    DeviceView(viewModel: deviceViewModel)
                                }
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
        }
        .background(Color(red: 0.93, green: 0.94, blue: 0.94)
            .toolbar(content: {
                EditButton()
            })
)
    }

    func delete(_ indexSet: IndexSet) {
        viewModel.onRemoveDevice(indexSet)
    }
}

#Preview {
    DeviceListView(viewModel: DevicesViewModel(currentDevice: .init(udid: "1234", title: "Device 1", mlsThumbprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "26 89 F2 1C 4A F3 9D 9D", isProteusVerificationEnabled: false, e2eIdentityCertificate: E2EIdentityCertificate(status: .valid, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""")), otherDevices: [
    DeviceInfoViewModel(udid: "123e4", title: "Device 2", mlsThumbprint: "skfjnskjdsfnskjn", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "skjdabfnksjkqa", isProteusVerificationEnabled: true, e2eIdentityCertificate: E2EIdentityCertificate(status: .revoked, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""")),
    DeviceInfoViewModel(udid: "123f4", title: "Device 3", mlsThumbprint: "skfjnskjddfnskjn", deviceKeyFingerprint: """
               b4 47 60 78 a3 1f 12 f9
               be 7c 98 3b 1f f1 f0 53
               ae 2a 01 6a 31 32 49 d0
               e9 fd da 5e 21 fd 06 ae
               """, proteusID: "skjdabfnksjkas", isProteusVerificationEnabled: false, e2eIdentityCertificate: E2EIdentityCertificate(status: .notActivated, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""")),
    DeviceInfoViewModel(udid: "123g4", title: "Device 4", mlsThumbprint: "skfjnskjdffnskjn", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "skjdabfnkscjka", isProteusVerificationEnabled: true, e2eIdentityCertificate: E2EIdentityCertificate(status: .valid, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
"""))
    ]))
}
