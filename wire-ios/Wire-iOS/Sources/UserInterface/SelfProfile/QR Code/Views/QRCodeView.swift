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

struct QRCodeView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: UserQRCodeViewModel

    @State private var scannedCode: String?
    @State private var capturedImage: UIImage?

    // MARK: - View

    var body: some View {
        shareView
        .background(Color.viewBackground.edgesIgnoringSafeArea(.all))
    }

    private var shareView: some View {
           VStack {
               QRCodeCard(profileLinkQRCode: viewModel.profileLinkQRCode,
                          handle: viewModel.handle,
                          profileLink: viewModel.profileLink)
               InfoText()
               Spacer()
               ShareButtons(capturedImage: $capturedImage,
                            profileLink: viewModel.profileLink,
                            captureQRCode: captureQRCode)
           }
           .padding()
    }

    private func captureQRCode() {
            capturedImage = captureImage(from: QRCodeCard(
                profileLinkQRCode: viewModel.profileLinkQRCode,
                handle: viewModel.handle,
                profileLink: viewModel.profileLink
            ))
        }

    private func captureImage<Content: View>(from view: Content) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        let targetSize = CGSize(width: 400, height: 400)
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationView {
        QRCodeView(viewModel: UserQRCodeViewModel(
            profileLink: "http://link,knfieoqrngorengoejnbgjroqekgnbojqre3bgqjore3bgn3ejjeqrlw3bglrejkbgnjorqwbglejrqg",
            handle: "handle"))
    }
}
