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

    init(viewModel: MeetingLinkViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(Strings.description)
                            .font(for: .body1)

                        content
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
                .overlay(alignment: .bottom) {
                    if viewModel.copyConfirmation != nil {
                        Text(Strings.copied)
                            .font(for: .body2)
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            .padding(12)
                            .background(ColorTheme.Backgrounds.surface.color, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.Strokes.outline.color))
                            .padding(16)
                            .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.copied)
                    }
                }

                Button(Strings.copy) {
                    viewModel.copyLink(isClipboardEnabled: isClipboardEnabled)
                }
                .wireButtonStyle(.primary)
                .disabled(!canCopy)
                .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.copy)
                .padding([.horizontal, .bottom], 16)
            }
            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
            .background(ColorTheme.Backgrounds.background.color)
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Localizable.WireMeetings.Schedule.Cancel.button) { dismiss() }
                        .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.cancel)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task { await viewModel.load() }
        .task(id: viewModel.copyConfirmation) {
            guard viewModel.copyConfirmation != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            viewModel.copyConfirmation = nil
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
