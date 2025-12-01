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
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

struct ShareLinkPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor

    @StateObject private var viewModel: ViewModel = .init()
    
    var body: some View {
        NavigationStack {
            content()
                .tint(ColorTheme.Base.primary(wireAccentColor).color)
        }
    }
    
    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack {
                Text("TODO: Password")
            }
            .padding()
        }
    }
}

#Preview {
    ShareLinkPasswordView()
}
