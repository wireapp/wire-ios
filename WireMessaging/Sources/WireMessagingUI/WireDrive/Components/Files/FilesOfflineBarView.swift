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

struct FilesOfflineBarView: View {
    @ScaledMetric private var scale: CGFloat = 1
    let showHint: Bool

    var body: some View {
        VStack(spacing: 8) {
            bar()
            if showHint {
                hint()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func bar() -> some View {
        Text(L10n.Localizable.General.NoInternet.title.uppercased())
            .font(for: .subline2)
            .multilineTextAlignment(.center)
            .foregroundColor(ColorTheme.Base.onWarning.color)
            .frame(maxWidth: .infinity)
            .padding(4)
            .background(ColorTheme.Base.warning.color)
            .cornerRadius(6 * scale)
    }

    @ViewBuilder
    private func hint() -> some View {
        Text(L10n.Localizable.Conversation.WireCells.Files.offlineModeHint)
            .font(for: .subline1)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    VStack(spacing: 0) {
        Text("content above the bar")
            .opacity(0.5)
            .padding()

        Divider()

        FilesOfflineBarView(showHint: true)

        Divider()

        Text("content below the bar")
            .opacity(0.5)
            .padding()
    }
}
