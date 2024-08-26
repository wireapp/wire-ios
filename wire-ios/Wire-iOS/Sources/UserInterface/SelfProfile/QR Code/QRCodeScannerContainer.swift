//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct QRCodeScannerContainer: View {

    @Binding var scannedCode: String?
    @Binding var latestCode: String?
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            QRCodeScannerView(scannedCode: $scannedCode, latestCode: $latestCode)

            VStack {
                Spacer()
                if let latestCode {
                    Button {
                        openScannedCode(latestCode)
                    } label: {
                        Text("Tap to connect")
                            .padding()
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }

    private func openScannedCode(_ code: String) {
        guard let url = URL(string: code) else {
            print("Invalid URL")
            return
        }

        openURL(url) { success in
            if !success {
                print("Failed to open URL")
            }
        }
    }
}
