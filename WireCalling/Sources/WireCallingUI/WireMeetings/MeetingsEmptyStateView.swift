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

package struct MeetingsEmptyStateView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.List.EmptyState

    var body: some View {
        ZStack {
            VStack(spacing: 28) {
                Spacer(minLength: 0)
                Text(Strings.title)
                    .font(.textStyle(.h2))
                    .foregroundColor(ColorTheme.Backgrounds.onSurfaceVariant.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .accessibilityIdentifier("meetingsEmptyStateTitle")

                Text(Strings.subtitle)
                    .font(.textStyle(.body1))
                    .foregroundColor(ColorTheme.Backgrounds.onSurfaceVariant.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .accessibilityIdentifier("meetingsEmptyStateSubtitle")
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTheme.Backgrounds.surfaceVariant.color)
        .overlay(
            arrowView
                .frame(width: 120, height: 200)
                .padding(.trailing, 40)
                .padding(.top, 40)
                .allowsHitTesting(false)
                .accessibilityHidden(true),
            alignment: .topTrailing
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder private var arrowView: some View {
        Image(.meetingsEmptyArrow)
            .resizable()
            .renderingMode(.original)
    }
}

#Preview {
    MeetingsEmptyStateView()
}
