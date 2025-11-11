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

struct MeetingsEmptyStateView: View {
    let title: String
    let subtitle: String

    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.textStyle(.h2))
                .foregroundColor(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.textStyle(.body1))
                .foregroundColor(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MeetingsEmptyStateView(
        title: "No upcoming meetings",
        subtitle: "Start or schedule a meeting with team members, guests, or external parties."
    )
}
