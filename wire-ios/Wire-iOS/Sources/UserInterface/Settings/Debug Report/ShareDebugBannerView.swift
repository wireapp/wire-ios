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
import WireDesign
import WireLocators

struct ShareDebugBannerView: View {

    @ObservedObject var viewModel: ShareDebugReportViewModel

    var body: some View {
        Button { viewModel.showOptions() } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "exclamationmark.bubble")
                    .font(for: .body2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.title)
                        .font(for: .body2)
                        .multilineTextAlignment(.leading)
                    Text(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.message)
                        .font(for: .subline1)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(for: .subline2)
                    .accessibilityHidden(true)
            }
            .foregroundColor(Color(ColorTheme.Backgrounds.onBackground))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(ColorTheme.Backgrounds.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.title)
        .accessibilityIdentifier(Locators.SettingsPage.shareDebugBanner.rawValue)
        .confirmationDialog(
            L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet.title,
            isPresented: $viewModel.isShowingOptions,
            titleVisibility: .visible
        ) {
            if viewModel.canShareViaWire {
                Button(L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet.shareViaWire) {
                    Task { await viewModel.shareViaWire() }
                }
                .accessibilityIdentifier(Locators.ShareDebugReportPage.shareViaWireButton.rawValue)
            }
            if viewModel.canSendEmail {
                Button(L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet.sendEmail) {
                    Task { await viewModel.sendEmail() }
                }
                .accessibilityIdentifier(Locators.ShareDebugReportPage.sendEmailButton.rawValue)
            }
            Button(L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet.share) {
                Task { await viewModel.shareViaActivitySheet() }
            }
            .accessibilityIdentifier(Locators.ShareDebugReportPage.shareButton.rawValue)
            Button(L10n.Localizable.General.cancel, role: .cancel) {}
                .accessibilityIdentifier(Locators.ShareDebugReportPage.cancelButton.rawValue)
        } message: {
            Text(L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet.message)
        }
    }
}

#Preview {
    ShareDebugBannerView(viewModel: .init(userSession: nil, mainCoordinator: nil))
        .padding()
        .background(Color(.systemGroupedBackground))
}
