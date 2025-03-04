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
    func switchBackendView(email: String, environment: BackendEnvironmentInfo) -> SwitchBackendConfirmationView

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
           // dismiss()
        } label: {
            Text(Strings.proceed)
                .font(.textStyle(.buttonBig))
        }
        .wireButtonStyle(.primary)
    }

}

// MARK: - Previews

//#Preview("Regular fonts") {
//    BackgroundView()
//        .overlay(
//            ZStack {
//                SwitchBackendConfirmationPreview()
//                    .padding()
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        )
//}
//
//#Preview("Large fonts") {
//    VStack {
//        BackgroundView()
//            .overlay(
//                ZStack {
//                    SwitchBackendConfirmationPreview()
//                        .padding()
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//            )
//    }
//    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
//}
