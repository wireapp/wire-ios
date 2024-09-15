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
        ScrollView {
            VStack(spacing: 2) {
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
                .padding(.top)
            }
        }
            .navigationTitle(Text(verbatim: "WireTextStyle -> SwiftUI.Font"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
func WireTextStyleUIFontMappingPreview() -> UIViewController {

    let labels = WireTextStyle.allCases
        .map { textStyle in
            let label = UILabel()
            label.text = "\(textStyle)"
            label.font = .font(for: textStyle)
            label.adjustsFontForContentSizeCategory = true
            label.textAlignment = .center
            return label
        }

    let stackView = UIStackView(arrangedSubviews: labels)
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.distribution = .equalSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false

    let viewController = UIViewController()
    viewController.navigationItem.title = "WireTextStyle -> SwiftUI.Font"
    viewController.navigationItem.largeTitleDisplayMode = .never
    viewController.view.backgroundColor = .systemBackground
    viewController.view.addSubview(stackView)
    NSLayoutConstraint.activate([
        stackView.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor),
        stackView.topAnchor.constraint(equalToSystemSpacingBelow: viewController.view.safeAreaLayoutGuide.topAnchor, multiplier: 2),
        viewController.view.trailingAnchor.constraint(equalTo: stackView.safeAreaLayoutGuide.trailingAnchor)
    ])

    return UINavigationController(rootViewController: viewController)
}
