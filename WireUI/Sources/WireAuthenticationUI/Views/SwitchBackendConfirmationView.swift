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

package struct SwitchBackendConfirmationView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @State private var internalShowFullDetails: Bool = false
    // The purpose is to change `showFullDetails` in tests.
    @Binding var externalShowFullDetails: Bool?

    private typealias Strings = L10n.SwitchBackendConfirmation

    private let viewModel: SwitchBackendConfirmationViewModel
    private let onShowDetails: () -> Void

    private var showFullDetails: Bool {
        externalShowFullDetails ?? internalShowFullDetails
    }

    package init(
        viewModel: SwitchBackendConfirmationViewModel,
        onShowDetails: @escaping () -> Void,
        externalShowFullDetails: Binding<Bool?> = .constant(nil)
    ) {
        self.viewModel = viewModel
        self.onShowDetails = onShowDetails
        self._externalShowFullDetails = externalShowFullDetails
    }

    package var body: some View {
        VStack(spacing: 20) {
            title
            backendDetails
            buttons
        }
        .padding()
        .interactiveDismissDisabled()
    }

    private var title: some View {
        Text(Strings.title)
            .font(.textStyle(.h2))
            .foregroundStyle(Color.primaryText)
            .multilineTextAlignment(.center)
    }

    private var backendDetails: some View {
        showFullDetails ? AnyView(fullDetails) : AnyView(shortDetails)
    }

    private var fullDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                ForEach(viewModel.items, id: \.title) { model in
                    itemView(
                        title: model.title,
                        value: model.value,
                        isURL: model.isURL
                    )
                }
            }
        }
    }

    private var shortDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                ForEach(viewModel.items.prefix(2), id: \.title) { model in
                    itemView(
                        title: model.title,
                        value: model.value,
                        isURL: model.isURL
                    )
                }
                Button {
                    withAnimation {
                        internalShowFullDetails.toggle()
                        onShowDetails()
                    }
                } label: {
                    Text(Strings.showDetails)
                        .font(.textStyle(.body1))
                }
                .wireButtonStyle(.link)
            }
        }
    }

    private func itemView(
        title: String,
        value: String,
        isURL: Bool = false
    ) -> some View {
        VStack {
            Text(title)
                .foregroundStyle(Color.secondaryText)
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
            viewModel.handleEvent(.didCancel)
            dismiss()
        } label: {
            Text(Strings.cancel)
                .font(.textStyle(.buttonBig))
        }
        .wireButtonStyle(.secondary)
    }

    private var proceedButton: some View {
        Button {
            viewModel.handleEvent(.didConfirm)
            dismiss()
        } label: {
            Text(Strings.proceed)
                .font(.textStyle(.buttonBig))
        }
        .wireButtonStyle(.primary)
    }

}

// MARK: - Previews

#Preview("Details - Collapsed") {
    SwitchBackendConfirmationViewPreview(showFullDetails: false)
}

#Preview("Details - Expanded") {
    SwitchBackendConfirmationViewPreview(showFullDetails: true)
}
