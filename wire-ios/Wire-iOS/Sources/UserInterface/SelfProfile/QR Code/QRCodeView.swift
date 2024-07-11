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
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: UserQRCodeViewModel
    @State private var selectedMode: QRCodeMode = .share
    @State private var scannedCode: String?
    @State private var latestCode: String?
    @State private var capturedImage: UIImage?
    @Environment(\.openURL) private var openURL

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
                .captureImage(capturedImage: $capturedImage)
            InfoText()
            Spacer()
            ShareButtons(viewModel: viewModel, capturedImage: $capturedImage)
        }
        .padding(.horizontal, 24)
    }

    private var scanView: some View {
        QRCodeScannerContainer(scannedCode: $scannedCode, latestCode: $latestCode)
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

extension View {

    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct CaptureImageView<Content: View>: View {
    @Binding var capturedImage: UIImage?
    let content: () -> Content

    var body: some View {
        content()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.capturedImage = content().snapshot()
                }
            }
    }
}

extension View {
    func captureImage(capturedImage: Binding<UIImage?>) -> some View {
        CaptureImageView(capturedImage: capturedImage) { self }
    }
}
