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
import WireDesign
import WireLocators
import WireMessagingDomain
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.Details
private typealias Accessibility = L10n.Accessibility.Conversation.Details
private typealias Locator = Locators.WireDrive.ConversationDetailsSharedDriveOptionsPage

package struct ConversationSharedDriveOptionsView: View {
    @StateObject package var viewModel: ConversationSharedDriveOptionsViewModel
    @ScaledMetric private var iconSize: CGFloat = 26

    private let onClose: () -> Void

    package init(
        viewModel: @autoclosure @escaping () -> ConversationSharedDriveOptionsViewModel,
        onClose: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.onClose = onClose
    }

    package var body: some View {
        List {
            sharedDriveToggleSection
            participantsSection
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(10)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color)
        .navigationTitle(L10n.Localizable.Conversation.WireCells.Files.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { closeButton } }
    }

    private var sharedDriveToggleSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 15))
                    .frame(width: 20)

                Text(Strings.SharedDriveToggleSection.title)
                    .font(for: .body1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .accessibilityIdentifier(Locator.toggleSectionTitle)

                Spacer()

                Toggle("", isOn: $viewModel.isSharedDriveEnabled)
                    .labelsHidden()
                    .disabled(true)
                    .accessibilityIdentifier(Locator.toggle)
            }
        } footer: {
            Text(Strings.SharedDriveToggleSection.Footer.title)
                .font(for: .subline1)
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
                .accessibilityIdentifier(Locator.toggleSectionFooter)
        }
    }

    private var participantsSection: some View {
        Section {
            ForEach(viewModel.participants) { participant in
                participantRow(participant)
            }
        } header: {
            Text(Strings.SharedDriveAccessSection.Header.title.uppercased())
                .font(for: .h4)
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
                .accessibilityIdentifier(Locator.participantsSectionHeader)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.SharedDriveAccessSection.Footer.title)
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .accessibilityIdentifier(Locator.participantsSectionFooterTitle)
                Text(Strings.SharedDriveAccessSection.Footer.subtitle)
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .accessibilityIdentifier(Locator.participantsSectionFooterSubtitle)
            }
        }
    }

    private var closeButton: some View {
        Button(
            action: { onClose() },
            label: { Image(.close) }
        )
        .accessibilityLabel(Accessibility.SharedDrive.closeButton)
        .accessibilityIdentifier(Locators.ConversationDetailsPage.close.rawValue)
        .tint(ColorTheme.Backgrounds.onBackground.color)
    }

    @ViewBuilder
    private func participantRow(_ participant: WireDriveParticipant) -> some View {
        Label {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        HStack(spacing: 5) {
                            Text(participant.displayName)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .font(for: .body1)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                                .accessibilityIdentifier(Locator.participantName)

                            if participant.isSelfUser {
                                Text("(\(Strings.SharedDriveAccessSection.you))")
                                    .font(for: .body1)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                            }
                        }

                        ForEach(viewModel.trailingImages(for: participant), id: \.self) {
                            Image(uiImage: $0)
                        }
                    }

                    Text("@" + participant.handle)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(for: .subline1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                        .accessibilityIdentifier(Locator.participantHandle)
                }

                Spacer()

                Text(participant.role.rawValue)
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .accessibilityIdentifier(Locator.participantRole)
            }.padding(.vertical, 2)
        } icon: {
            icon(participant)
                .frame(width: iconSize, height: iconSize)
        }
    }

    @ViewBuilder
    private func icon(_ item: WireDriveParticipant) -> some View {
        ZStack {
            if let blockedOrPendingApprovalAvatarIcon = viewModel.blockedOrPendingApprovalAvatarIcon(for: item) {
                Color(ColorTheme.Backgrounds.onBackground.color)
                Image(uiImage: blockedOrPendingApprovalAvatarIcon)
                    .resizable()
                    .frame(width: iconSize / 2, height: iconSize / 2)
                    .foregroundStyle(ColorTheme.Backgrounds.onInverted.color)

            } else if let iconData = item.iconData {
                if let image = iconData.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(uiColor: iconData.color)

                    Text(iconData.initials)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .foregroundStyle(ColorTheme.Backgrounds.background.color)
                        .padding(4)
                }
            } else {
                Image(.unavailableUser)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .clipShape(Circle())
    }
}

#Preview {
    NavigationStack {
        ConversationSharedDriveOptionsView(
            viewModel: ConversationSharedDriveOptionsViewModel(participants: .mocked()),
            onClose: {}
        )
    }
}
