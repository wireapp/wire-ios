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
import WireCallingDomain
import WireDesign
import WireLocators

struct MeetingLinkView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.Link

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isClipboardEnabled) private var isClipboardEnabled
    @State private var viewModel: MeetingLinkViewModel
    @State private var viewerContentHeight: CGFloat = 0
    @State private var actionAreaHeight: CGFloat = 0
    @State private var navigationTopInset: CGFloat = 0

    init(viewModel: MeetingLinkViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                formContent
                    .overlay(alignment: .bottom) {
                        if viewModel.copyConfirmation != nil {
                            Text(Strings.copied)
                                .font(for: .body2)
                                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                                .padding(12)
                                .background(
                                    ColorTheme.Backgrounds.surface.color,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.Strokes.outline.color))
                                .padding(16)
                                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.copied)
                        }
                    }

                actionArea
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        actionAreaHeight = height
                    }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.top
            } action: { inset in
                navigationTopInset = inset
            }
            .background(ColorTheme.Backgrounds.background.color)
            .navigationTitle(viewModel.isGeneratingLink ? Strings.generate : Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.didCreateLink ? Strings.close : L10n.Localizable.WireMeetings.Schedule.Cancel
                        .button) {
                            dismiss()
                        }
                        .disabled(viewModel.isCreating)
                        .accessibilityIdentifier(viewModel.didCreateLink ? Locators.WireMeetings.MeetingLink
                            .close : .cancel)
                }
            }
        }
        .presentationDetents(sheetDetents)
        .interactiveDismissDisabled(viewModel.isCreating)
        .task { await viewModel.load() }
        .onDisappear {
            viewModel.password = ""
            viewModel.confirmPassword = ""
        }
        .alert(Strings.createError, isPresented: $viewModel.hasRotationError) {
            Button(L10n.Localizable.WireMeetings.Schedule.Error.Alert.ok) {}
        }
        .task(id: viewModel.copyConfirmation) {
            guard viewModel.copyConfirmation != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            viewModel.copyConfirmation = nil
        }
    }

    private var isEditingPassword: Bool { viewModel.isGeneratingLink && !viewModel.didCreateLink }

    private var sheetDetents: Set<PresentationDetent> {
        if isEditingPassword {
            [.large]
        } else if viewerContentHeight > 0, actionAreaHeight > 0 {
            // The system adds the bottom safe area to a height detent.
            [.height(ceil(viewerContentHeight + actionAreaHeight + navigationTopInset))]
        } else {
            [.medium]
        }
    }

    private var actionArea: some View {
        VStack(spacing: 16) {
            if !viewModel.isGeneratingLink, viewModel.canRotate {
                Button(action: viewModel.beginRotation) {
                    Text(Strings.generate)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .wireButtonStyle(.secondary)
                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.generate)
                .padding(.horizontal, 16)
            }

            Button {
                if isEditingPassword {
                    Task { await viewModel.createLink() }
                } else {
                    viewModel.copyLink(isClipboardEnabled: isClipboardEnabled)
                }
            } label: {
                Text(isEditingPassword ? (viewModel.isCreating ? Strings.creating : Strings.generate) : Strings
                    .copy)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .wireButtonStyle(.primary)
            .disabled(isEditingPassword ?
                viewModel.isCreating || !viewModel.isPasswordValid || !viewModel.passwordsMatch : !canCopy)
            .accessibilityIdentifier(isEditingPassword ? Locators.WireMeetings.MeetingLink.create : .copy)
            .padding([.horizontal, .bottom], 16)
        }
        .padding(.top, 16)
    }

    @ViewBuilder private var formContent: some View {
        if isEditingPassword {
            Form {
                Section {
                    Text(Strings.consequence)
                        .font(for: .body1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.consequence)
                }
                MeetingPasswordSection(
                    password: $viewModel.password,
                    confirmPassword: $viewModel.confirmPassword,
                    isPasswordValid: viewModel.isPasswordValid,
                    passwordsMatch: viewModel.passwordsMatch,
                    isDisabled: viewModel.isCreating,
                    generatePassword: viewModel.generatePassword,
                    copyPassword: { viewModel.copyPassword(isClipboardEnabled: isClipboardEnabled) }
                )
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(Strings.description)
                        .font(for: .body1)
                        .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.consequence)
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    viewerContentHeight = height
                }
            }
            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Strings.title)
                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.loading)
        case let .loaded(link):
            Text(verbatim: link.url.absoluteString)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ColorTheme.Backgrounds.surface.color, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ColorTheme.Strokes.outline.color))
                .accessibilityLabel(Strings.title)
                .accessibilityValue(link.url.absoluteString)
                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.url)

            Text(link.hasPassword ? Strings.passwordProtected : Strings.notPasswordProtected)
                .font(for: .body2)
                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.passwordState)
        case .unavailable, .failed:
            Text(viewModel.state == .unavailable ? Strings.unavailable : Strings.loadError)
                .font(for: .body1)
                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.error)
            Button(L10n.Localizable.WireMeetings.retry) {
                Task { await viewModel.load() }
            }
            .wireButtonStyle(.tertiary)
            .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.retry)
        }
    }

    private var canCopy: Bool {
        guard case .loaded = viewModel.state else { return false }
        return isClipboardEnabled
    }
}
