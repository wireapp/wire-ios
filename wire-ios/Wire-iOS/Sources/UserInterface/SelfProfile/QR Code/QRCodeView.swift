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

    // MARK: Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: - ViewModel

    @ObservedObject var viewModel: UserQRCodeViewModel

    // MARK: - Properties

    @State private var selectedMode: QRCodeMode = .share
    @State private var scannedCode: String?
    @State private var latestCode: String?
    @State private var capturedImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $selectedMode) {
                ForEach(QRCodeMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            switch selectedMode {
            case .share:
                shareView
            case .scan:
                scanView
            }
        }
        .background(Color.primaryViewBackground.edgesIgnoringSafeArea(.all))
        .onChange(of: scannedCode) { newValue in
            if let code = newValue {
                openScannedCode(code)
            }
        }
    }

    private var shareView: some View {
        VStack {
            QRCodeCard(viewModel: viewModel)
            InfoText()
            Spacer()
            ShareButtons(viewModel: viewModel, capturedImage: $capturedImage, captureQRCode: captureQRCode)
        }
        .padding()
    }

    private var scanView: some View {
        QRCodeScannerContainer(scannedCode: $scannedCode, latestCode: $latestCode)
    }

    private func captureQRCode() {
        capturedImage = captureImage(from: QRCodeCard(viewModel: viewModel))
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

// MARK: - Preview

#Preview {
    NavigationView {
        QRCodeView(viewModel: UserQRCodeViewModel(
            profileLink: "http://link,knfieoqrngorengoejnbgjroqekgnbojqre3bgqjore3bgn3ejjeqrlw3bglrejkbgnjorqwbglejrqg",
            accentColor: .blue,
            handle: "handle"))
    }
}
