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

public struct DeactivatableScrollView<Content>: View
where Content : View {

    private let axes: Axis.Set
    private let content: () -> Content

    public init(
        _ axes: Axis.Set = .vertical,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axes = axes
        self.content = content
    }

    public var body: some View {

        if #available(iOS 16.4, *) {
            ScrollView(axes) {
                content()
                    .background(GeometryReader { geometryProxy in
                        Color.clear.preference(key: ScrollViewContentSizeKey.self, value: geometryProxy.size)
                    })
            }.scrollDisabled(true)
                .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView(axes, content: content)
        }
    }
}

private struct ScrollViewContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value.width = max(value.width, nextValue().width)
        value.height = max(value.height, nextValue().height)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Rectangle()
            .foregroundStyle(Color(UIColor.systemGray6))
            .ignoresSafeArea()

        HStack {
            DeactivatableScrollView {
                Text("Scrollable")
                    .font(.title2)
                    .padding()
                let words = "Lorem ipsum dolor sit amet consectetur adipiscing elit"
                    .split(separator: " ")
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .padding(.vertical, 1)
                        .padding(.horizontal, 8)
                }
            }
            .frame(height: 200)
            .background(Color(UIColor.white))

            Rectangle()
                .foregroundStyle(Color(UIColor.systemGray2))
                .frame(width: 1)
                .padding()

            DeactivatableScrollView {
                Text("Not Scrollable")
                    .font(.title2)
                    .padding()
                let words = "Lorem ipsum dolor"
                    .split(separator: " ")
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .padding(.vertical, 1)
                        .padding(.horizontal, 8)
                }
            }
            .frame(height: 200)
            .background(Color(UIColor.white))
        }
    }
}
