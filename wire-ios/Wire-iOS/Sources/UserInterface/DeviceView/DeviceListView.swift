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
    @State var data: DevicesViewModel
    var body: some View {

        NavigationView {
            List {
                Section(header: Text("CURRENT DEVICE")) {
                    NavigationLink(destination: DeviceDetailsView(device: data.currentDevice)) {
                        DeviceView(device: data.currentDevice)
                    }
                }
                Section(header: Text("OTHER DEVICES")) {
                    ForEach(data.otherDevices) { device in
                        NavigationLink(destination: DeviceDetailsView(device: device)) {
                            DeviceView(device: device)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Your Devices")
    }
}

#Preview {
    DeviceListView(data: DevicesViewModel(currentDevice: .init(udid: "1234", title: "Device 1", mlsThumbprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "26 89 F2 1C 4A F3 9D 9D", isSecured: true, isVerified: false, e2eIdentityCertificate: E2EIdentityCertificate(status: false, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""")), otherDevices: [
    DeviceInfo(udid: "123e4", title: "Device 2", mlsThumbprint: "skfjnskjdsfnskjn", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "skjdabfnksjkqa", isSecured: true, isVerified: false, e2eIdentityCertificate: E2EIdentityCertificate(status: false, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""")),
    DeviceInfo(udid: "123f4", title: "Device 3", mlsThumbprint: "skfjnskjddfnskjn", deviceKeyFingerprint: """
               b4 47 60 78 a3 1f 12 f9
               be 7c 98 3b 1f f1 f0 53
               ae 2a 01 6a 31 32 49 d0
               e9 fd da 5e 21 fd 06 ae
               """, proteusID: "skjdabfnksjkas", isSecured: true, isVerified: false, e2eIdentityCertificate: E2EIdentityCertificate(status: false, serialNumber: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""")),
    DeviceInfo(udid: "123g4", title: "Device 4", mlsThumbprint: "skfjnskjdffnskjn", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "skjdabfnkscjka", isSecured: true, isVerified: false, e2eIdentityCertificate: E2EIdentityCertificate(status: false, serialNumber: """
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
