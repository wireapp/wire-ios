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

struct CertificateDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    var certificateDetails: String
    @State var isMenuPresented = false
    var isDownloadAndCopyEnabled: Bool = true
    var performDownload: (() -> Void)?
    var performCopy: ((String) -> Void)?
    var body: some View {
        HStack {
            Spacer()
            Text(L10n.Localizable.Device.Details.Certificate.details)
            Spacer()
            SwiftUI.Button(action: {
                dismiss()
            }, label: {
                Image(.close)
            }).padding()
        }.background(Color.backgroundColor)
        ScrollView {
            Text(certificateDetails)
                .font(Font.sfMonoSmall)
                .padding()
                .frame(maxHeight: .infinity)
        }

        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack {
                if isDownloadAndCopyEnabled {
                    HStack {
                        SwiftUI.Button(action: {
                            performDownload?()
                        },
                                       label: {
                            Image(.download)
                        }).padding()
                        SwiftUI.Button(action: {
                            performDownload?()
                        },
                                       label: {
                            Text(L10n.Localizable.Content.Message.download).font(UIFont.normalRegularFont.swiftUIfont.bold())
                        }).padding()
                            .foregroundColor(.black)
                         .font(UIFont.mediumSemiboldFont.swiftUIfont)
                        Spacer()
                        SwiftUI.Button(action: {
                            isMenuPresented.toggle()
                        }, label: {
                            Image(.more).padding(.trailing, 16)
                        })
                        .confirmationDialog("...", isPresented: $isMenuPresented) {
                            SwiftUI.Button(action: {
                                performCopy?(certificateDetails)
                            }, label: {
                                Text( L10n.Localizable.Device.Details.copytoclipboard).foregroundColor(.black)
                            })
                            .foregroundColor(.black)
                        } message: {
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            // The background will extend automatically to the edge
            .background(Color.white)
            .border(isDownloadAndCopyEnabled ? Color.black : .white, width: 0.5)
        }
        .ignoresSafeArea()
        .padding(.top, 8)
        .background(Color.white)
    }
}

#Preview {
    CertificateDetailsView(
        certificateDetails: """
-----BEGIN CERTIFICATE---
\(String.randomString(
length: 1500
))
-------END CERTIFICATE-----
"""
    )
}
#if DEBUG
extension String {
    static func randomString(
        length: Int
    ) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((
            0..<length
        ).map {
            _ in letters.randomElement()!
        })
    }
}
#endif
