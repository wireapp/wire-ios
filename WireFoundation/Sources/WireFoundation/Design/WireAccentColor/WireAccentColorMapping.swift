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

public final class WireAccentColorMapping: ObservableObject, Sendable {

    public typealias UIColorMapping = @Sendable (WireAccentColor) -> UIColor
    public typealias ColorMapping = @Sendable (WireAccentColor) -> Color

    let uiColorMapping: UIColorMapping
    let colorMapping: ColorMapping

    public convenience init(uiColorMapping: @escaping UIColorMapping) {
        self.init(uiColorMapping: uiColorMapping) { uiColor in
            Color(uiColor: uiColorMapping(uiColor))
        }
    }

    public init(
        uiColorMapping: @escaping UIColorMapping,
        colorMapping: @escaping ColorMapping
    ) {
        self.uiColorMapping = uiColorMapping
        self.colorMapping = colorMapping
    }

    func uiColor(for accentColor: WireAccentColor) -> UIColor {
        uiColorMapping(accentColor)
    }

    func color(for accentColor: WireAccentColor) -> Color {
        colorMapping(accentColor)
    }
}


private struct WireAccentColorMappingKey: EnvironmentKey {
    static let defaultValue = WireAccentColorMapping { accentColor in
        switch accentColor {
        case .blue: .systemBlue
        case .green: .systemGreen
        case .red: .systemRed
        case .amber: .systemYellow
        case .turquoise: .systemTeal
        case .purple: .systemPurple
        }
    }
}

public extension EnvironmentValues {
    var wireAccentColorMapping: WireAccentColorMapping {
        get { self[WireAccentColorMappingKey.self] }
        set { self[WireAccentColorMappingKey.self] = newValue }
    }
}

// MARK: - Previews

#Preview {
    WireAccentColorMappingPreview()
}

@ViewBuilder @MainActor
func WireAccentColorMappingPreview() -> some View {
    VStack {
        ForEach (WireAccentColor.allCases, id: \.self) { accentColor in
            MappingTestView()
                .wireAccentColor(accentColor)
            if accentColor != WireAccentColor.allCases.last {
                Divider()
            }
        }
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
