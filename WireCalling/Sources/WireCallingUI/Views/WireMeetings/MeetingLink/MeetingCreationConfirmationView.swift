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

package import SwiftUI
package import Foundation
import WireDesign
import WireLocators

package struct MeetingCreationConfirmationView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.Link

    @Environment(\.isClipboardEnabled) private var isClipboardEnabled
    @State private var copyConfirmation: UUID?

    let link: URL
    let isInstant: Bool
    let hasEmailInvitees: Bool
    let onClose: () -> Void

    package init(link: URL, isInstant: Bool, hasEmailInvitees: Bool = false, onClose: @escaping () -> Void) {
        self.link = link
        self.isInstant = isInstant
        self.hasEmailInvitees = hasEmailInvitees
        self.onClose = onClose
    }

    var confirmationDescription: String {
        hasEmailInvitees ? Strings.Confirmation.description : Strings.Confirmation.sharingDescription
    }

    package var body: some View {
        Group {
            if isInstant {
                content
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                NavigationStack {
                    content
                        .navigationTitle(Strings.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) { closeButton }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .task(id: copyConfirmation) {
            guard copyConfirmation != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            copyConfirmation = nil
        }
    }

    private var content: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isInstant {
                        HStack(alignment: .top) {
                            Text(Strings.Confirmation.instantTitle)
                                .font(for: .body1)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                            closeButton
                        }
                    }
                    if !isInstant {
                        Text(confirmationDescription)
                            .font(for: .body1)
                    }
                    linkView
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Strings.title)
                        .accessibilityValue(link.absoluteString)
                        .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.url)
                }
                .padding(16)
            }

            Button(Strings.copy) {
                guard isClipboardEnabled else { return }
                UIPasteboard.general.string = link.absoluteString
                copyConfirmation = UUID()
                UIAccessibility.post(notification: .announcement, argument: Strings.copied)
            }
            .buttonStyle(MeetingCreationCopyButtonStyle())
            .disabled(!isClipboardEnabled)
            .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.copy)
            .padding([.horizontal, .bottom], 16)
        }
        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        .background(ColorTheme.Backgrounds.background.color)
        .overlay(alignment: .center) {
            if copyConfirmation != nil {
                Text(Strings.copied)
                    .font(for: .body2)
                    .foregroundStyle(ColorTheme.Backgrounds.onInverted.color)
                    .padding(12)
                    .background(ColorTheme.Backgrounds.inverted.color, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier(Locators.WireMeetings.MeetingLink.copied)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder private var linkView: some View {
        if isInstant {
            Label {
                Text(verbatim: link.absoluteString)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                Image(systemName: "link")
                    .accessibilityHidden(true)
            }
            .font(for: .body1)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(verbatim: link.absoluteString)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ColorTheme.Backgrounds.surface.color, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var closeButton: some View {
        Button(Strings.Confirmation.close, action: onClose)
            .font(for: .body1)
            .accessibilityIdentifier("meetingCreationConfirmationClose")
    }
}

private struct MeetingCreationCopyButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                if isEnabled {
                    Rectangle().fill(.tint)
                } else {
                    (colorScheme == .dark ? BaseColorPalette.Grays.gray80 : BaseColorPalette.Grays.gray50).color
                }
            }
            .foregroundStyle(isEnabled ? ColorTheme.Base.onPrimary.color : ColorTheme.Base.onDisabled.color)
            .font(for: .buttonBig)
            .clipShape(.rect(cornerRadius: 16))
    }
}
