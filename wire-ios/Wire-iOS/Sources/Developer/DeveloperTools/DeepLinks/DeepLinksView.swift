//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

struct DeepLinksView: View {

    // MARK: - Properties

    @StateObject var viewModel: DeepLinksViewModel

    @State private var urlString = ""

    @State private var isQRScannerPresented: Bool = false

    // MARK: - Views

    var body: some View {
        List {
            Section("Open deeplink") {
                TextField(
                    "Link",
                    text: $urlString,
                    prompt: Text("Enter deeplink")
                )
                Button("Open") {
                    viewModel.openLink(urlString: urlString)
                }
                .disabled(urlString.isEmpty)
            }

            Section("Switch backend") {
                ForEach(DeepLinksViewModel.Backend.allCases, id: \.self) { backend in
                    Text(backend.rawValue).onTapGesture {
                        viewModel.openSwitchBackendLink(for: backend)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItem {
                Button("Scan", systemImage: "qrcode") {
                    isQRScannerPresented = true
                }
            }
        }
        .alert(
            isPresented: $viewModel.isShowingAlert,
            error: viewModel.error,
            actions: {}
        )
        .sheet(isPresented: $isQRScannerPresented) {
            QRCodeScannerView { scannedCode in
                urlString = scannedCode
                viewModel.openLink(urlString: scannedCode)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
}

struct QRCodeScannerView: UIViewControllerRepresentable {

    var onQRCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let viewController = QRCodeScannerViewController()
        viewController.onQRCodeScanned = onQRCodeScanned
        return viewController
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        // Nothing to update here.
    }
}

// MARK: - Previews

#Preview {
    DeepLinksView(viewModel: DeepLinksViewModel())
}
