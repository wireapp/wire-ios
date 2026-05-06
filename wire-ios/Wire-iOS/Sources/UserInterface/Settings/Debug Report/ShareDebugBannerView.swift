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

    let onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "exclamationmark.bubble")
                        .font(for: .body3)
                        .accessibilityHidden(true)
                        .foregroundColor(ColorTheme.Backgrounds.onBackground.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.title)
                            .font(for: .body3)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(ColorTheme.Backgrounds.onBackground.color)

                        Text(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.message)
                            .font(for: .h4)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(ColorTheme.Content.Base.secondary.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Image(systemName: "chevron.right")
                    .font(for: .h3)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ColorTheme.Backgrounds.surface.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.title)
        .accessibilityIdentifier(Locators.SettingsPage.shareDebugBanner.rawValue)
    }
}

#Preview {
    ShareDebugBannerView(onTap: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}
