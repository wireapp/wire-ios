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

struct ShareButtons: View {

    // MARK: - Properties

    @State private var isShareTextSheetPresented = false
    @State private var isShareImageSheetPresented = false

    @Binding var capturedImage: UIImage?

    var profileLink: String
    var captureQRCode: () -> Void

    // MARK: - view

    var body: some View {
        VStack {
            Button(L10n.Localizable.Qrcode.ShareProfileLink.Button.title) {
                isShareTextSheetPresented = true
            }
            .font(.textStyle(.buttonBig))
            .buttonStyle(SecondaryButtonStyle())
            .sheet(isPresented: $isShareTextSheetPresented) {
                ShareSheet(activityItems: [profileLink])
            }

            Button(L10n.Localizable.Qrcode.ShareQrcode.Button.title) {
                captureQRCode()
                isShareImageSheetPresented = true
            }
            .font(.textStyle(.buttonBig))
            .buttonStyle(SecondaryButtonStyle())
            .sheet(isPresented: $isShareImageSheetPresented) {
                ShareSheet(activityItems: [capturedImage as Any])
            }
        }
    }
}


// MARK: - Preview

#Preview {
    ShareButtons(
        capturedImage: .constant(nil),
        profileLink: "http://link",
        captureQRCode: {})
}
