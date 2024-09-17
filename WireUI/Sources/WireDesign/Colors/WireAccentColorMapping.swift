//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public extension WireAccentColorMapping {

    convenience init() {
        self.init { wireAccentColor in
            switch wireAccentColor {
            case .blue:
                .init(light: .blue500Light, dark: .blue500Dark)
            case .green:
                .init(light: .green500Light, dark: .green500Dark)
            case .red:
                .init(light: .red500Light, dark: .red500Dark)
            case .amber:
                .init(light: .amber500Light, dark: .amber500Dark)
            case .turquoise:
                .init(light: .turquoise500Light, dark: .turquoise500Dark)
            case .purple:
                .init(light: .purple500Light, dark: .purple500Dark)
            }
        }
    }
}

private extension UIColor {

    convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, *)
#Preview {
    WireAccentColorMappingPreview()
}

@available(iOS 16.0, *) @ViewBuilder @MainActor
func WireAccentColorMappingPreview() -> some View {
    NavigationStack {
        VStack {
            ForEach(WireAccentColor.allCases, id: \.self) { accentColor in
                MappingTestView()
                    .wireAccentColor(accentColor)
                if accentColor != WireAccentColor.allCases.last {
                    Divider()
                }
            }
        }
        .environment(\.wireAccentColorMapping, WireAccentColorMapping())
        .navigationTitle(Text(verbatim: "WireAccentColors"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MappingTestView: View {
    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.wireAccentColorMapping) private var wireAccentColorMapping
    var body: some View {
        VStack {
            Text(verbatim: "\(String(describing: wireAccentColor))")
            Circle().foregroundStyle(wireAccentColorMapping.color(for: wireAccentColor))
        }
    }
}
