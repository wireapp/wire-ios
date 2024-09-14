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

public protocol WireAccentColorMapping: ObservableObject {
    func uiColor(for accentColor: WireAccentColor) -> UIColor
    func color(for accentColor: WireAccentColor) -> Color
}

final class WireAccentColorMapper: ObservableObject, WireAccentColorMapping {
    func uiColor(for accentColor: WireAccentColor) -> UIColor {
        fatalError()
    }
    func color(for accentColor: WireAccentColor) -> Color {
        switch accentColor {
        case .blue:
                .blue
        case .green:
                .green
        case .red:
                .red
        case .amber:
                .yellow
        case .turquoise:
                .teal
        case .purple:
                .purple
        }
    }
}

//@available(iOS 17, *)
//#Preview {
//    MappingTestView_()
//}

#Preview {
    VStack {
        MappingTestView()
            .wireAccentColor(.green)
    }
    .environmentObject(WireAccentColorMapper())
}

private struct MappingTestView: View {

    @Environment(\.wireAccentColor) private var wireAccentColor
    @EnvironmentObject private var wireAccentColorMapper: WireAccentColorMapping & ObservableObject

    init() {}

    var body: some View {
        VStack {
            Text(verbatim: "\(String(describing: wireAccentColor))")
            if let patternImage {
                Image(uiImage: patternImage)
            } else {
                Text(verbatim: "patternImage == nil")
            }
            Circle()
                .foregroundStyle(wireAccentColorMapper.color(for: wireAccentColor))
        }
    }
}

let patternImage = UIImage(systemName: "pencil.circle")
let patternColor = UIColor(patternImage: patternImage!)

private final class MappingTestView_: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = patternColor
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
