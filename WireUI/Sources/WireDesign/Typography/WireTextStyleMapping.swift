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

public extension WireTextStyleMapping {

    convenience init() {
        self.init { textStyle in
            .font(for: textStyle)
        } fontMapping: { textStyle in
            .textStyle(textStyle)
        }
    }
}

@available(iOS 16, *)
#Preview("SwiftUI.Font") {
    WireTextStyleFontMappingPreview()
}

@available(iOS 17, *)
#Preview("UIKit.UIFont") {
    WireTextStyleUIFontMappingPreview()
}

@available(iOS 16, *) @ViewBuilder @MainActor
func WireTextStyleFontMappingPreview() -> some View {
    NavigationStack {
            VStack {
                ForEach(WireTextStyle.allCases, id: \.self) { textStyle in
                    if textStyle != .buttonSmall {
                        Text("\(textStyle)")
                                .wireTextStyle(textStyle)
                                .environment(\.wireTextStyleMapping, WireTextStyleMapping())
                    } else {
                        Text(verbatim: "buttonSmall not implemented")
                            .foregroundStyle(Color.red)
                    }
                }
        }
        .navigationTitle(Text(verbatim: "WireTextStyle -> SwiftUI.Font"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 16, *) @ViewBuilder @MainActor
func WireTextStyleUIFontMappingPreview() -> some View {
    NavigationStack {
        VStack {
            Rectangle().foregroundStyle(Color.clear)
                VStack {
                    ForEach(WireTextStyle.allCases, id: \.self) { textStyle in
                        LabelRepresentable(textStyle: textStyle)
                    }
                }
            Rectangle().foregroundStyle(Color.clear)
        }
        .navigationTitle(Text(verbatim: "WireTextStyle -> SwiftUI.Font"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LabelRepresentable: UIViewRepresentable {
    var textStyle: WireTextStyle
    func makeUIView(context: Context) -> UILabel { .init() }
    func updateUIView(_ label: UILabel, context: Context) {
        label.text = "\(textStyle)"
        label.font = .font(for: textStyle)
        label.textAlignment = .center
    }
}
