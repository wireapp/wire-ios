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

import UIKit

// MARK: - Bar

protocol Bar {
    var weight: Float { get }
}

// MARK: - BarController

final class BarController: UIViewController {
    // MARK: Internal

    private(set) var bars: [UIViewController] = []

    func present(bar: UIViewController) {
        if bars.contains(bar) {
            return
        }

        bars.append(bar)

        bars.sort { left, right -> Bool in
            let leftWeight = (left as? Bar)?.weight ?? 0
            let rightWeight = (right as? Bar)?.weight ?? 0

            return leftWeight < rightWeight
        }

        addChild(bar)
        updateStackView()
        bar.didMove(toParent: self)
    }

    func dismiss(bar: UIViewController) {
        guard let index = bars.firstIndex(of: bar) else {
            return
        }
        bar.willMove(toParent: nil)
        bars.remove(at: index)

        UIView.animate(withDuration: 0.35) {
            self.stackView.removeArrangedSubview(bar.view)
            bar.view.removeFromSuperview()
        }

        bar.removeFromParent()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill

        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }

    // MARK: Private

    private let stackView = UIStackView()

    private func updateStackView() {
        UIView.animate(withDuration: 0.35) {
            for arrangedSubview in self.stackView.arrangedSubviews {
                self.stackView.removeArrangedSubview(arrangedSubview)
                arrangedSubview.removeFromSuperview()
            }

            self.bars.map(\.view).forEach(self.stackView.addArrangedSubview)
        }
    }
}
