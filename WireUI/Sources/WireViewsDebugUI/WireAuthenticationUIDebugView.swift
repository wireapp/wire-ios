//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAuthenticationUI

public struct WireAuthenticationUIDebugView: View {

    enum PresentationStyle {
        case fullScreen
        case sheet
    }

    enum PresentationItem: String, Identifiable {
        var id: String { rawValue }

        case background
        case switchBackend

        var presentationStyle: PresentationStyle {
            switch self {
            case .background:
                .fullScreen
            case .switchBackend:
                .sheet
            }
        }
    }

    @State private var presentedItem: PresentationItem?

    public init() {}

    public var body: some View {
        List {
            Button(
                action: { presentedItem = .background },
                label: { Text("Background") }
            )
            Button(
                action: { presentedItem = .switchBackend },
                label: { Text("Switch backend confirmation") }
            )
        }
//        .fullScreenCover(item: $presentedItem) { item in
//            if item.presentationStyle == .fullScreen {
//                fullScreenCoverContent(for: item)
//            }
//        }
        .sheet(item: $presentedItem) { item in
            if item.presentationStyle == .sheet {
                sheetContent(for: item)
            }
        }

    }

    @ViewBuilder
    private func fullScreenCoverContent(for item: PresentationItem) -> some View {
        if item == .background {
            fullscreenCover(content: { BackgroundView() })
        }
    }

    @ViewBuilder
    private func sheetContent(for item: PresentationItem) -> some View {
        if item == .switchBackend {
            SwitchBackendHostingViewControllerWrapper()
        }
    }

    @ViewBuilder
    private func fullscreenCover(content: () -> some View) -> some View {
        content()
            .overlay {
                HStack {
                    Spacer()
                    VStack {
                        Button(
                            action: { presentedItem = nil },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.largeTitle)
                            }
                        )
                        .frame(width: 50, height: 50)
                        Spacer()
                    }
                }
                .padding(.top, 40)
                .padding(.trailing, 20)
            }
    }

    private struct SwitchBackendHostingViewControllerWrapper: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIHostingController<SwitchBackendConfirmationView> {
            createSwitchBackendSheetController(
                viewModel: SwitchBackendConfirmationViewModel(
                    backendName: "Backend Name",
                    backendURL: "https://backend.url",
                    backendWSURL: "wss://backend.ws.url",
                    blacklistURL: "https://blacklist.url",
                    teamsURL: "https://teams.url",
                    accountsURL: "https://accounts.url",
                    websiteURL: "https://website.url",
                    action: { _ in }
                )
            )
        }

        func updateUIViewController(_ uiViewController: UIHostingController<SwitchBackendConfirmationView>, context: Context) {}

        func createSwitchBackendSheetController(viewModel: SwitchBackendConfirmationViewModel) ->  UIHostingController<SwitchBackendConfirmationView> {
            let hostingController = SwitchBackendConfirmationHostingController(viewModel: viewModel)
            hostingController.modalPresentationStyle = .pageSheet

            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }

            return hostingController
        }
    }

}

#Preview {
    NavigationView {
        WireAuthenticationUIDebugView()
    }
}
