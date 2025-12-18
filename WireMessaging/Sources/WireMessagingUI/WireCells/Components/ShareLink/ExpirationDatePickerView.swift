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
import WireDesign

private typealias Strings = L10n.Localizable.Conversation.WireCells.ShareLink.Expiration

struct ExpirationDatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor

    @StateObject private var viewModel: ViewModel

    package init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(Strings.description)
                        .font(for: .subline1)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)

                    Toggle(Strings.addExpirationToggle, isOn: Binding(
                        get: { viewModel.isExpirationEnabled },
                        set: { newValue in
                            if newValue, !viewModel.isExpirationEnabled {
                                viewModel.enableExpirationDate()
                            } else if !newValue, viewModel.isExpirationEnabled {
                                viewModel.disableExpirationDate()
                            } else {
                                viewModel.isExpirationEnabled = newValue
                            }
                        }
                    ))
                    .font(for: .body1)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(ColorTheme.Backgrounds.surface.color)
                    }

                    Spacer(minLength: 8)

                    if viewModel.isExpirationEnabled {
                        // provide a non-optional binding to the child view so the child doesn't need to accept Date?
                        let binding = Binding<Date>(
                            get: { viewModel.expirationDate ?? viewModel.defaultExpirationDate },
                            set: { viewModel.expirationDate = $0 }
                        )

                        ExpirationPickerContent(
                            expirationDate: binding
                        )
                    }
                }
                .disabled(viewModel.isSaving)
                .padding()
            }
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent() }
            .tint(wireAccentColor.color)
            .background(ColorTheme.Backgrounds.background.color)
            .alert(
                Strings.UnableToAddExpiration.title,
                isPresented: $viewModel.isPresentingExpirationDateError,
                actions: {
                    Button(
                        Strings.UnableToAddExpiration.action,
                        action: {
                            Task {
                                await viewModel.save()
                            }
                        }
                    )

                    Button(
                        L10n.Localizable.General.cancel,
                        role: .cancel,
                        action: {}
                    )
                },
                message: { Text(Strings.UnableToAddExpiration.message) }
            )
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Text(L10n.Localizable.General.cancel)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await viewModel.save() }
            } label: {
                Text(L10n.Localizable.General.save)
                    .bold()
            }
            .disabled(!viewModel.canSave || viewModel.isSaving)
        }
    }
}

/// A separate view to handle the "Expires" label, the segmented date/time controls, and the DatePicker.
struct ExpirationPickerContent: View {
    @Environment(\.wireAccentColor) private var wireAccentColor

    @Binding var expirationDate: Date
    @State private var dateInThePast: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Strings.datePickerTitle)
                    .font(for: .body1)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                Spacer()

                DatePicker("", selection: $expirationDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.automatic)
                    .labelsHidden()
            }
            .padding(.vertical, 6)
            .padding(.horizontal)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(ColorTheme.Backgrounds.surface.color)
            }

            if $expirationDate.wrappedValue < Date() {
                Text(Strings.dateNotSupported)
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Base.error.color)
                    .padding(.leading, 4)
                    .onAppear {
                        dateInThePast.toggle()
                    }
            }
        }
    }
}

// MARK: - Custom Segmented Button

/// Custom button style to replicate the appearance of an internal segmented control.
struct DateSegmentButton: View {
    @Environment(\.wireAccentColor) private var wireAccentColor

    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(for: .body1)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(isSelected ? ColorTheme.Base.primary(wireAccentColor).color : ColorTheme.Backgrounds
                    .onBackground.color)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ColorTheme.Backgrounds.background.color)
                }
        }
        .buttonStyle(.plain) // ensure button taps are handled reliably inside List rows
    }
}

 #Preview("With initial date") {
     ExpirationDatePickerView(viewModel: .preview(
        date: Calendar.current.date(byAdding: .hour, value: 2, to: Date()))
     )
     .colorScheme(.light)
 }

 #Preview("Date in the past") {
     ExpirationDatePickerView(viewModel: .preview(
        date: Calendar.current.startOfDay(for: Date()))
     )
     .colorScheme(.light)
 }

 #Preview("No initial date") {
     ExpirationDatePickerView(
        viewModel: .preview(date: nil)
     )
     .colorScheme(.dark)
 }
