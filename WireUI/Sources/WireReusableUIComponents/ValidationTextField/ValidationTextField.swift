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

import Combine
import SwiftUI
import WireDesign

public struct ValidationTextField: View {
    @FocusState private var isFocusedState: Bool
    @ScaledMetric private var fieldHeight: CGFloat = 48
    @Environment(\.wireAccentColor) private var wireAccentColor

    @Binding var textInput: String
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    private let title: String?
    private let placeholder: String?

    public init(
        title: String?,
        placeholder: String?,
        textInput: Binding<String>,
        errorMessage: Binding<String?> = .constant(nil),
        isFocused: Binding<Bool> = .constant(false)
    ) {
        self._textInput = textInput
        self._errorMessage = errorMessage
        self._isFocused = isFocused
        self.title = title
        self.placeholder = placeholder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                Text(title)
                    .font(for: .h4)
                    .foregroundColor(titleColor)
            }

            HStack {
                TextField(placeholder ?? "", text: $textInput)
                    .autocorrectionDisabled()
                    .font(for: .body1)
                    .frame(height: fieldHeight)
                    .focused($isFocusedState)
                    .onChange(of: $isFocusedState.wrappedValue) { newValue in
                        isFocused = newValue
                    }
                    .onChange(of: isFocused) { newValue in
                        $isFocusedState.wrappedValue = newValue
                    }
                    .onAppear {
                        $isFocusedState.wrappedValue = isFocused
                    }

                Spacer()

                Button(action: {
                    if !shouldShowErrorMessage {
                        textInput = ""
                    }

                }, label: {
                    Image(systemName: shouldShowErrorMessage ? "exclamationmark.circle" : "xmark.circle.fill")
                        .foregroundColor(iconColor)
                        .frame(width: 16, height: 16)
                        .padding(16)
                })
            }
            .padding(.leading, 16)
            .frame(height: fieldHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        borderColor,
                        lineWidth: 1
                    )
            )

            if shouldShowErrorMessage, let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(titleColor)
            }
        }
    }

    // MARK: - Helpers

    private var shouldShowErrorMessage: Bool {
        errorMessage != nil
    }

    private var titleColor: Color {
        if shouldShowErrorMessage {
            ColorTheme.Base.error.color
        } else {
            Color(wireAccentColor)
        }
    }

    private var borderColor: Color {
        if shouldShowErrorMessage {
            ColorTheme.Base.error.color
        } else {
            Color(wireAccentColor)
        }
    }

    private var iconColor: Color {
        if shouldShowErrorMessage {
            ColorTheme.Base.error.color
        } else {
            ColorTheme.Buttons.Secondary.onEnabled.color
        }
    }
}

#Preview {
    ValidationTextField_PreviewView(
        viewModel: ValidationTextField_PreviewViewModel()
    )
}

private struct ValidationTextField_PreviewView: View {
    @StateObject var viewModel: ValidationTextField_PreviewViewModel

    var body: some View {
        ValidationTextField(
            title: "Username",
            placeholder: "Enter username",
            textInput: $viewModel.text,
            errorMessage: $viewModel.errorMessage
        ).padding()
    }
}

private final class ValidationTextField_PreviewViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        $text
            .map { input -> String? in
                if input.isEmpty {
                    return "Field cannot be empty"
                } else if input.count < 3 {
                    return "Must be at least 3 characters"
                } else {
                    return nil
                }
            }.assign(to: &$errorMessage)
    }
}
