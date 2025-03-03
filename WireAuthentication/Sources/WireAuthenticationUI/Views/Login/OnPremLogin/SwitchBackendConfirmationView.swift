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
import WireAuthenticationAPI
import WireDesign

package protocol SwitchBackendConfirmationBuilder {

    @MainActor
    func switchBackendView(environment: BackendEnvironmentInfo) -> SwitchBackendConfirmationView

}

package struct SwitchBackendConfirmationView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @State private var showFullDetails: Bool = false

    private typealias Strings = L10n.SwitchBackendConfirmation

    private let viewModel: SwitchBackendConfirmationViewModel

    package init(
        viewModel: SwitchBackendConfirmationViewModel
    ) {
        self.viewModel = viewModel
    }

    package var body: some View {
        VStack(spacing: 20) {
            title
            backendDetails
            buttons
        }
        .padding()
        .interactiveDismissDisabled()
        .background(ColorTheme.Backgrounds.surface.color)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.Backgrounds.surface.color, lineWidth: 1)
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    private var title: some View {
        Text(Strings.title)
            .font(.textStyle(.h2))
            .foregroundStyle(Color.primaryText)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .minimumScaleFactor(0.8)
    }

    private var backendDetails: some View {
        Group {
            if showFullDetails {
                fullDetails
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            } else {
                shortDetails
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            }
        }
        .animation(.default, value: showFullDetails)
    }

    private var contentHeight: CGFloat {
        UIScreen.main.bounds.height * 0.4
    }

    private var fullDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(viewModel.items, id: \.title) { model in
                    itemView(
                        title: model.title,
                        value: model.value,
                        isURL: model.isURL
                    )
                }
            }
        }
        .frame(maxHeight: contentHeight)
    }

    private var shortDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(viewModel.items.prefix(2), id: \.title) { model in
                    itemView(
                        title: model.title,
                        value: model.value,
                        isURL: model.isURL
                    )
                }
                Button {
                    withAnimation {
                        showFullDetails.toggle()
                    }
                } label: {
                    Text(Strings.showDetails)
                        .font(.textStyle(.body1))
                }
                .wireButtonStyle(.link)
            }
        }
        .frame(maxHeight: contentHeight)
    }

    private func itemView(
        title: String,
        value: String,
        isURL: Bool = false
    ) -> some View {
        VStack {
            Text(title)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .foregroundStyle(Color.primaryText)
                .accessibilityTextContentType(isURL ? .fileSystem : .plain)
        }
    }

    private var buttons: some View {
        VStack(spacing: 6) {
            cancelButton
            proceedButton
        }
    }

    private var cancelButton: some View {
        Button {
            viewModel.cancel()
            dismiss()
        } label: {
            Text(Strings.cancel)
                .font(.textStyle(.buttonBig))
        }
        .wireButtonStyle(.secondary)
    }

    private var proceedButton: some View {
        Button {
            Task { await viewModel.confirm() }
            dismiss()
        } label: {
            Text(Strings.proceed)
                .font(.textStyle(.buttonBig))
        }
        .wireButtonStyle(.primary)
    }

}

// MARK: - Previews

#Preview() {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            MockDependencies().switchBackendView(environment:  BackendEnvironmentInfo(
                title:  "backendName",
                endpoints: BackendURLs(
                    backendURL: URL(string: "backendURL")!,
                    backendWSURL: URL(string: "backendWSURL")!,
                    blackListURL: URL(string: "blacklistURL")!,
                    teamsURL: URL(string: "teamsURL")!,
                    accountsURL: URL(string: "accountsURL")!,
                    websiteURL: URL(string: "websiteURL")!
                )
            ))
        }
}



//package struct SwitchBackendConfirmationView11: View {
//
//    private let viewModel: SwitchBackendConfirmationViewModel
//
//    package init(
//        viewModel: SwitchBackendConfirmationViewModel
//    ) {
//        self.viewModel = viewModel
//    }
//
//    @Environment(\.dismiss) private var dismiss
//
//    package var body: some View {
//        ZStack {
//            // Transparent background
//            Color.clear
//                .edgesIgnoringSafeArea(.all)
//                .onTapGesture { dismiss() } // Dismiss when tapping outside
//
//            VStack(spacing: 16) {
//                Text("Redirect to an on-premises backend?")
//                    .font(.title3)
//                    .bold()
//
//                Text("If you proceed, you will be redirected to the following on-premises backend to log in:")
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.secondary)
//
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("**Backend name:** \("backendName")")
//                    Text("**Backend URL:** 11111111")
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//                Button("Show details") {
//                    // Implement details view if necessary
//                }
//                .foregroundColor(.blue)
//
//                HStack {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color(.systemGray5))
//                    .cornerRadius(8)
//
//                    Button("Proceed") {
//                        dismiss()
//                        // Handle backend switch logic here
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                }
//            }
//            .padding()
//            .frame(width: 350)
//            .background(Color.white) // Alert content
//            .cornerRadius(16)
//            .shadow(radius: 10)
//            .overlay(
//                RoundedRectangle(cornerRadius: 16)
//                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
//            )
//        }
//        .background(ClearBackgroundView()) // Fixes SwiftUI's white background issue
//    }
//}
//
//struct ClearBackgroundView1: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> UIViewController {
//        let controller = UIViewController()
//        controller.view.backgroundColor = .clear // Fully transparent
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
//}
//struct ClearBackgroundView: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIView {
//        return InnerView()
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {
//    }
//
//    private class InnerView: UIView {
//        override func didMoveToWindow() {
//            super.didMoveToWindow()
//
//            superview?.superview?.backgroundColor = .clear
//        }
//
//    }
//}




//struct SwitchBackendConfirmationModal: View {
//    let viewModel: SwitchBackendConfirmationViewModel
//    //@Binding var isPresented: Bool
//
//    var body: some View {
//        ZStack {
//            // Dimmed background
//            Color.black.opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//                .onTapGesture {
//                    //isPresented = false
//                }
//
//            // Centered Modal
//            VStack {
//                SwitchBackendConfirmationView(viewModel: viewModel)
//                    .background(Color.white)
//                    .cornerRadius(16)
//                    .shadow(radius: 10)
//            }
//            .padding()
//        }
//    }
//}
