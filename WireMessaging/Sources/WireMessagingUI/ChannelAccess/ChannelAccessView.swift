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
import WireMessagingDomain
import WireMessagingDomainSupport

package struct ChannelAccessView: View {

    @ObservedObject var viewModel: ChannelAccessViewModel

    package init(viewModel: ChannelAccessViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(
                    footer: Text(L10n.Localizable.ChannelAccessLevel.accessFooter)
                        .font(.footnote)
                        .foregroundColor(ColorTheme.Base.secondaryText.color)
                ) {
                    accessOption(
                        title: L10n.Localizable.ChannelAccessLevel.public,
                        level: .public,
                        disabled: viewModel.isPublicDisabled
                    )

                    accessOption(
                        title: L10n.Localizable.ChannelAccessLevel.private,
                        level: .private
                    )
                }.background(.clear)

                if viewModel.showParticipantPermissions {
                    Section(
                        header: Text(L10n.Localizable.ChannelAccessLevel.participantsHeader),
                        footer: Text(L10n.Localizable.ChannelAccessLevel.participantsFooter)
                            .font(.footnote)
                            .foregroundColor(
                                ColorTheme.Base.secondaryText.color
                            )
                    ) {
                        permissionOption(
                            title: L10n.Localizable.ChannelAccessLevel.admins,
                            permission: .admins
                        )
                        permissionOption(
                            title: L10n.Localizable.ChannelAccessLevel.everyone,
                            permission: .everyone
                        )
                    }.background(.clear)
                }
            }
            .background(ColorTheme.Backgrounds.background.color)
            .alert(isPresented: $viewModel.showPrivateAccessConfirmation) {
                Alert(
                    title: Text(L10n.Localizable.ChannelAccessLevel.ChangeLevelAlert.title),
                    message: Text(L10n.Localizable.ChannelAccessLevel.ChangeLevelAlert.message),
                    primaryButton: .default(Text(L10n.Localizable.ChannelAccessLevel.ChangeLevelAlert.Button.change)) {
                        Task { await viewModel.confirmPrivateAccessChange() }
                    },
                    secondaryButton: .cancel(Text(L10n.Localizable.ChannelAccessLevel.ChangeLevelAlert.Button.cancel))
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color.ignoresSafeArea())
    }

    private func accessOption(title: String, level: ChannelAccessLevel, disabled: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(
                    disabled ? ColorTheme.Base.secondaryText.color : ColorTheme.Backgrounds.onSurface.color
                )
                .font(
                    viewModel.settings.accessLevel == level ? .headline : .body
                )
            Spacer()
            if viewModel.settings.accessLevel == level {
                Checkmark(accentColor: viewModel.accentColor)
            }
        }
        .contentShape(Rectangle())
        .frame(height: 40)
        .onTapGesture {
            Task { await viewModel.selectAccessLevel(level) }
        }
        .disabled(disabled)
    }

    private func permissionOption(title: String, permission: ChannelAccessLevelPermission) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                .font(
                    viewModel.settings.participantPermission == permission ? .headline : .body
                )
            Spacer()
            if viewModel.settings.participantPermission == permission {
                Checkmark(accentColor: viewModel.accentColor)
            }
        }
        .contentShape(Rectangle())
        .frame(height: 40)
        .onTapGesture {
            Task { await viewModel.selectParticipantPermission(permission) }
        }
    }

    struct Checkmark: View {

        let accentColor: Color

        var body: some View {
            Image("Check", bundle: .resources)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 22)
                .foregroundColor(accentColor)
        }
    }
}

struct ChannelAccessView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                ChannelAccessView(viewModel: ChannelAccessViewModel(
                    accentColor: .green,
                    useCase: ChannelAccessUseCase(
                        permission: nil,
                        repository: MockChannelRepositoryProtocol()
                    )
                ))

            }
            .previewDisplayName("Initially Public")

            NavigationStack {
                ChannelAccessView(
                    viewModel: ChannelAccessViewModel(
                        accentColor: .blue,
                        useCase: ChannelAccessUseCase(
                            permission: .everyone,
                            repository: MockChannelRepositoryProtocol()
                        )
                    )
                )
            }
            .previewDisplayName("Initially Private")
        }

    }
}
