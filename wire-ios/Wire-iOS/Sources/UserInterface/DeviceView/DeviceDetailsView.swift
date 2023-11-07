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

struct DeviceDetailsView: View {
    var viewModel: DeviceInfoViewModel
    @State var isVerified: Bool = false
    @State var isCertificatePresented: Bool = false
    var body: some View {
        NavigationView {
            List {
                Section("MLS with Ed25519 Signature") {
                    VStack(alignment: .leading) {
                        CopyValueView(title: "MLS THUMBPRINT", value: viewModel.mlsThumbprint)
                        Divider()
                        HStack {
                            Text("End-to-end Identity Certificate").font(.headline).multilineTextAlignment(.leading)
                            Spacer()
                        }
                        HStack {
                            Text("STATUS").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.leading)
                            Spacer()
                        }

                        HStack {
                            Text("Valid").foregroundColor(.green).font(.subheadline).bold()
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
                            Spacer()
                        }
                        Text("SERIAL NUMBER").font(.subheadline).foregroundColor(.gray).padding(.init(top: 4, leading: 0, bottom: 8, trailing: 8))
                        Text(viewModel.e2eIdentityCertificate.serialNumber).lineLimit(2)
                        SwiftUI.Button(action: getCertificate) {
                            Text("Get Certificate").padding()
                                .frame(maxWidth: .infinity, minHeight: 45)
                                .foregroundColor(.white)
                        }
                        .background {
                            Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 328, height: 48)
                            .background(Color(red: 0.02, green: 0.4, blue: 0.78))

                            .cornerRadius(16)
                        }

                        SwiftUI.Button(action: showCertificateDetails, label: {
                            HStack {
                                Spacer()
                                Text("Show Certificate Details").padding().multilineTextAlignment(.center)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }

                        }).background {
                            Rectangle()
                              .foregroundColor(.clear)
                              .frame(width: 328, height: 48)
                              .cornerRadius(16)
                              .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                  .inset(by: 0.5)
                                  .stroke(Color(red: 0.86, green: 0.88, blue: 0.89), lineWidth: 1)
                              )
                        }.foregroundColor(.black)
                    }
                }
                Section("Proteus Device Details") {
                    VStack(alignment: .leading) {
                        CopyValueView(title: "PROTEUS ID", value: viewModel.proteusID)
                        Text(viewModel.proteusID)
                        Divider()
                        Text("ADDED")
                        Text(viewModel.addedDate)
                        Divider()
                        CopyValueView(title: "DEVICE KEY FINGERPRINT", value: viewModel.deviceKeyFingerprint)
                        Divider()
                        VStack {
                            Toggle("Verified", isOn: $isVerified).font(.headline)
                            Text("""
                To verify your own device, compare this key  fingerprint with the same key fingerprint on another viewModel. Learn more
                Share this key fingerprint with other participants in a conversation, so that they can verify it and make sure the conversation is secure. Learn more
                """).multilineTextAlignment(.leading)
                        }
                        Divider()
                        Text("If fingerprints don’t match, reset the session to generate new encryption keys on both sides.").multilineTextAlignment(.leading)
                        SwiftUI.Button(action: resetSession, label: {
                            Text("Reset Session")
                                .frame(maxWidth: .infinity, minHeight: 45)
                        }).background {
                            Rectangle()
                              .foregroundColor(.clear)
                              .frame(maxWidth: .infinity, minHeight: 45)
                              .background(.white)
                              .cornerRadius(16)
                              .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                  .inset(by: 0.5)
                                  .stroke(Color(red: 0.86, green: 0.88, blue: 0.89), lineWidth: 1)
                              )
                        }.foregroundColor(.black)
                        Divider()
                        Text("Remove this device if you have stopped using it. You will be logged out of this device immediately.").multilineTextAlignment(.leading)
                        SwiftUI.Button(action: removeDevice, label: {
                            Text("Remove Device")
                                .frame(maxWidth: .infinity, minHeight: 45)
                        }).background {
                            Rectangle()
                              .foregroundColor(.clear)
                              .frame(maxWidth: .infinity, minHeight: 45)
                              .background(.white)
                              .cornerRadius(16)
                              .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                  .inset(by: 0.5)
                                  .stroke(Color(red: 0.86, green: 0.88, blue: 0.89), lineWidth: 1)
                              )
                        }.foregroundColor(.red)
                    }
                }.listStyle(.plain)
            }.navigationTitle(viewModel.title)
        }
    }

    func resetSession() {
        print("remove session")
    }

    func removeDevice() {
        print("remove device")
    }

    func showCertificateDetails() {
        print("show certificate")
    }

    func getCertificate() {
        print("get certificate")
    }
}

#Preview {
    DeviceDetailsView(viewModel: DeviceInfoViewModel(udid: "123g4", title: "Device 4", mlsThumbprint: "skfjnskjdffnskjn", deviceKeyFingerprint: """
b4 47 60 78 a3 1f 12 f9
be 7c 98 3b 1f f1 f0 53
ae 2a 01 6a 31 32 49 d0
e9 fd da 5e 21 fd 06 ae
""", proteusID: "skjdabfnkscjka", isProteusVerificationEnabled: true, e2eIdentityCertificate: E2EIdentityCertificate(status: .revoked, serialNumber: """
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
