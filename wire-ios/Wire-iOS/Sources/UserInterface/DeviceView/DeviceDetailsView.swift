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

extension Color {
    static var backgroundColor = Color(red: 0.93, green: 0.94, blue: 0.94)
    static var customRed = Color(red: 0.76, green: 0, blue: 0.07)
    static var customGreen = Color(red: 0.11, green: 0.47, blue: 0.2)
}

struct DeviceDetailsView: View {
    @State var viewModel: DeviceInfoViewModel
    @State var isCertificateViewPresented: Bool
    var body: some View {
        NavigationView {
            ScrollView {
                if !viewModel.mlsThumbprint.isEmpty {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 0) {
                            Text("MLS with Ed25519 Signature")
                        }
                        .padding(.bottom, 8)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, maxHeight: 42, alignment: .leading)
                        .background(Color(red: 0.93, green: 0.94, blue: 0.94))
                        
                        DeviceMLSView(viewModel: $viewModel).padding(.leading, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .padding(.trailing, 16)
                            .background(Color.white)
                    }
                            
                            if viewModel.e2eIdentityCertificate.status != .none {
                                    VStack(alignment: .leading) {
                                        DeviceDetailsE2EIdentityCertificateView(viewModel: $viewModel, isCertificateViewPreseneted: $isCertificateViewPresented).padding(.leading, 16)
                                
                                DeviceDetailsButtonsView(viewModel: $viewModel, isCertificateViewPresented: $isCertificateViewPresented)
                            }.background(Color.white)
                                    .padding(.top, 8)
                        }
                    
                }
                
                VStack(alignment: .leading) {
                    Text("Proteus Device Details").frame(height: 45).padding(.leading, 16)
                    DeviceDetailsProteusView(viewModel: $viewModel)
                    DeviceDetailsBottomView(viewModel: $viewModel)
                    
                }
            }
            .background(Color.backgroundColor)
            .environment(\.defaultMinListHeaderHeight, 10)
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    DeviceView(viewModel: viewModel).titleView
                }
            })
        }
        .background(Color.backgroundColor)
        .sheet(isPresented: $isCertificateViewPresented,
                onDismiss: didDismiss) {
            CertificateDetailsView(certificateDetails: viewModel.e2eIdentityCertificate.certificate, isMenuPresented: isCertificateViewPresented)
                .toolbar {
                    SwiftUI.Image(.attention).onTapGesture {
                        isCertificateViewPresented.toggle()
                    }
                }.navigationTitle("Certificate Details")
         }
    }
    
    func didDismiss() {
        
    }
}

struct DeviceMLSView: View {
    @Binding var viewModel: DeviceInfoViewModel
    var body: some View {
        VStack {
            CopyValueView(title: "MLS Thumbprint", value: viewModel.mlsThumbprint).frame(maxHeight: .infinity)
        }
    }
}

struct DeviceDetailsProteusView: View {
    @Binding var viewModel: DeviceInfoViewModel
    var body: some View {
            VStack(alignment: .leading) {
                CopyValueView(title: "PROTEUS ID", value: viewModel.proteusID).padding([.leading, .trailing], 16)
                Text(viewModel.proteusID).frame(maxHeight: .infinity).padding(.leading, 16)
                Divider()
                Text("ADDED").padding(.leading, 16)
                Text(viewModel.addedDate).padding(.leading, 16)
                Divider()
                CopyValueView(title: "DEVICE KEY FINGERPRINT", value: viewModel.deviceKeyFingerprint).padding([.leading, .trailing], 16)
                Divider()
                Toggle("Verified", isOn: $viewModel.isProteusVerificationEnabled).font(.headline).padding([.leading, .trailing, .bottom], 16)
            }.background(Color.white)
    }
}

struct DeviceDetailsBottomView: View {
    @Binding var viewModel: DeviceInfoViewModel
    var body: some View {
        Text("Wire gives every device a unique fingerprint. Compare them and verify your devices and conversations.").font(.footnote).padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.actionsHandler.resetSession()
                }
            } label: {
                Text("Reset Session").padding(.all, 16)
                    .foregroundColor(.black)
                    .font(UIFont.normalRegularFont.swiftUIfont.bold())
            }
            Spacer()
        }.background(Color.white)
        Text("If fingerprints don’t match, reset the session to generate new encryption keys on both sides.").font(.footnote).padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        HStack {
            SwiftUI.Button {
                Task {
                    viewModel.actionsHandler.removeDevice()
                }
            } label: {
                Text("Remove Device")
                    .padding(.all, 16)
                    .foregroundColor(.black).font(UIFont.normalRegularFont.swiftUIfont.bold())
            }
            Spacer()
        }.background(Color.white)
        Text("Remove this device if you have stopped using it. You will be logged out of this device immediately.")
            .font(.footnote)
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
    }
}


struct DeviceDetailsE2EIdentityCertificateView: View {
    @Binding var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPreseneted: Bool
    var body: some View {
        Text("End-to-end Identity Certificate").font(UIFont.normalSemiboldFont.swiftUIfont).multilineTextAlignment(.leading)
            .padding([.top, .bottom], 16)
        Text("Status").font(UIFont.mediumSemiboldFont.swiftUIfont).foregroundColor(.gray).multilineTextAlignment(.leading)
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
            Text("Serial Number").font(UIFont.smallSemiboldFont.swiftUIfont).foregroundColor(.gray).padding(.top, 8)
            Text(viewModel.e2eIdentityCertificate.serialNumber)
        }
    }
}

struct DeviceDetailsButtonsView: View {
    @Binding var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPresented: Bool
    var body: some View {
            if viewModel.e2eIdentityCertificate.certificate.isEmpty {
                SwiftUI.Button("Get Certificate") {
                    Task {
                        await viewModel.actionsHandler.fetchCertificate()
                    }
                }
                
            } else {
                if viewModel.e2eIdentityCertificate.isExpiringSoon {
                    SwiftUI.Button("Update Certificate") {
                        Task {
                            await viewModel.actionsHandler.fetchCertificate()
                        }
                    }
                }
                Divider()
                SwiftUI.Button(action:{
                    isCertificateViewPresented.toggle()
                } , label: {
                    HStack {
                        Text("Show Certificate Details").foregroundStyle(.black)
                            .font(UIFont.normalRegularFont.swiftUIfont.bold())
                        
                        Spacer()
                        Image(.rightArrow)
                        
                    }.padding()
                })
            }
    }
}
#Preview {
    DeviceDetailsView(viewModel: DeviceInfoViewModel(udid: "123g4", title: "Device 4", mlsThumbprint: """
3d c8 7f ff 07 c9 29 6e
3d c8 7f ff 07 c9 29 6e
65 68 7f ff 07 c9 29 6e
3d c8 7f ff 07 c9 65 6f
""", deviceKeyFingerprint: """
ff 25 d7 13 f3 18 84 7a
a5 4c 44 32 47 7c a0 b2
c2 b3 f9 8c 87 17 f6 9b
e8 f9 8c 87 17 f6 9b e8
""", proteusID: "3D C8 7F FF 07 C9 29 6E", isProteusVerificationEnabled: true, e2eIdentityCertificate: E2EIdentityCertificate(status: .revoked, serialNumber: """
e5:d5:e6:75:7e:04:86:07:
14:3c:a0:ed:9a:8d:e4:fd
""")), isCertificateViewPresented: false)
}
