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

public struct LegalHoldIndicatorView: View {

    @Environment(\.legalHoldIndicatorColor) private var legalHoldIndicatorColor

    public init() {}

    public var body: some View {
        Text("O")
            .foregroundStyle(.clear)
            .background {
                GeometryReader { geometry in
                    ZStack {
                        let diameter = min(geometry.size.width, geometry.size.height)

                        Circle()
                            .fill(legalHoldIndicatorColor)
                            .opacity(0.3)

                        Circle()
                            .fill(legalHoldIndicatorColor)
                            .frame(width: diameter * 10 / 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}

// MARK: - View Modifiers + Environment

public extension View {
    func legalHoldIndicatorColor(_ legalHoldIndicatorColor: Color) -> some View {
        modifier(LegalHoldIndicatorColorViewModifier(legalHoldIndicatorColor: legalHoldIndicatorColor))
    }
}

private extension EnvironmentValues {
    var legalHoldIndicatorColor: Color {
        get { self[LegalHoldIndicatorColorKey.self] }
        set { self[LegalHoldIndicatorColorKey.self] = newValue }
    }
}

struct LegalHoldIndicatorColorViewModifier: ViewModifier {
    var legalHoldIndicatorColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.legalHoldIndicatorColor, legalHoldIndicatorColor)
    }
}

private struct LegalHoldIndicatorColorKey: EnvironmentKey {
    /// Intentionally setting a wrong color so that it becomes quickly
    /// visible when the correct color isn't overridden.
    static let defaultValue = Color.mint
}

#Preview {
    LegalHoldIndicatorView()
}
