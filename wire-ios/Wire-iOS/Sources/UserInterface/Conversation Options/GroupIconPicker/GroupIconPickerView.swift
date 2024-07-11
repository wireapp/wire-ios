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
import WireDataModel

struct GroupIconPickerView: View {

    private static let cellSize: CGFloat = 60
    private let cornerRadius: CGFloat = 12

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: Self.cellSize))
    ]

    @StateObject var viewModel: GroupIconPickerViewModel

    init(viewModel: @autoclosure @escaping () -> GroupIconPickerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Select a color for the group avatar:")
                .fontWeight(.regular)
                .font(.body)

            sectionTitle("Group Color")
            colorList

            sectionTitle("Group Icon")
            ScrollView {
                emojiList
            }
        }
        .padding()
        .background(.background)
    }

    @ViewBuilder
    func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .font(.subheadline)
                .foregroundColor(.gray.darker(by: 50))
            Spacer()
        }
        .background(Color.gray)
    }

    private var emojiList: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.emojis) { item in
                Button {
                    viewModel.selectEmoji(item)
                } label: {
                    ZStack {
                        if viewModel.selectedEmoji == item {
                            CircleView()
                        }
                        Text(item.value)
                            .font(.system(size: 25))
                            .padding()
                    }
                }
            }
        }
    }

    private var colorList: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.selectItem(item)
                } label: {

                    ZStack {
                        Rectangle()
                            .foregroundColor(item.color)
                            .frame(
                                width: Self.cellSize,
                                height: Self.cellSize
                            )
                            .cornerRadius(cornerRadius)

                        if viewModel.selectedItem == item {
                            Image(systemName: "checkmark.circle.fill")
                                .tint(.white)
                        }
                    }
                }
            }
        }
    }
}

extension Emoji: Identifiable {
    var id: String {
        self.value
    }
}

struct CircleView: View {
    var body: some View {
        Circle()
            .fill(Color.gray)
            .frame(width: 40, height: 40) // Adjust the size as needed
            .overlay(
                Circle()
                    .stroke(Color.gray.darker(), lineWidth: 4) // Adjust the line width as needed
            )
    }
}

extension Color {
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(brightnessBy: -1 * percentage)
    }

    func adjust(brightnessBy percentage: CGFloat = 30.0) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: min(red + percentage / 100, 1.0),
            green: min(green + percentage / 100, 1.0),
            blue: min(blue + percentage / 100, 1.0),
            opacity: Double(alpha)
        )
    }
}
