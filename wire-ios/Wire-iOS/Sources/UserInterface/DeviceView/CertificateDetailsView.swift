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
    var certificateDetails: String
    @State var isMenuPresented = false

    var body: some View {
        List {
            SwiftUI.Text(certificateDetails)
        }
        .navigationTitle("Certificate Details")
        .toolbar {
            SwiftUI.Button("...") {
                isMenuPresented.toggle()
            }
            .confirmationDialog("...", isPresented: $isMenuPresented) {
                SwiftUI.Button("Copy to Clipboard") {

                }
                SwiftUI.Button("Download") {

                }
            } message: {
                Text("Select a new color")
            }
        }

    }
}

#Preview {
    CertificateDetailsView(certificateDetails: """
-----BEGIN CERTIFICATE---
\(String.randomString(length: 1500))
-------END CERTIFICATE-----
""")
}

extension String {
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }
}
