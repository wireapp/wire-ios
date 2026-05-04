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

struct ShareDebugBannerView: View {

    let action: () -> Void

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(for: .h3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.title)
                        .font(for: .h5)
                        .fontWeight(.semibold)
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
                    .fill(Color(ColorTheme.Base.primaryVariant(wireAccentColor)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(ColorTheme.Base.primary(wireAccentColor)))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Localizable.Self.Settings.ShareDebugReport.Banner.title)
    }
}

#Preview {
    ShareDebugBannerView {}
        .padding()
        .environment(\.wireAccentColor, .blue)
}
