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
import WireFoundation

public extension Color {

    init(_ accentColor: WireAccentColor) {
        self.init(UIColor(accentColor))
    }

}

// MARK: - Previews

#Preview {
    WireAccentColorMappingPreview()
}

@ViewBuilder @MainActor
func WireAccentColorMappingPreview() -> some View {
    NavigationStack {
        VStack {
            ForEach(WireAccentColor.allCases, id: \.self) { accentColor in
                MappingTestView()
                    .environment(\.wireAccentColor, accentColor)
                if accentColor != WireAccentColor.allCases.last {
                    Divider()
                }
            }
        }
        .navigationTitle(Text(verbatim: "WireAccentColors"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MappingTestView: View {

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        let foregroundColor = ColorTheme.Base.primary(wireAccentColor)
        VStack {
            Text(verbatim: "\(String(describing: wireAccentColor))")
            Circle().foregroundStyle(Color(foregroundColor))
        }
    }

}
