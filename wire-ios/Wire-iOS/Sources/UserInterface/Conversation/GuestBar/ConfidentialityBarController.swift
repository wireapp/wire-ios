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

import UIKit
import WireDesign

final class ConfidentialityBarController: UIViewController {

    // MARK: - State

    enum State: Equatable {
        case visible(color: UIColor, text: String)
        case hidden
    }

    // MARK: - Properties

    private let iconImageView = UIImageView()
    private let label = UILabel()
    private let container = UIView()

    private static let barHeight: CGFloat = 28

    private lazy var heightConstraint: NSLayoutConstraint = view.heightAnchor
        .constraint(equalToConstant: 0)

    private var _state: State = .hidden

    var state: State {
        get { _state }
        set { setState(newValue, animated: false) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateState(animated: false)
    }

    // MARK: - UI

    private func setupViews() {
        view.backgroundColor = .clear
        container.clipsToBounds = true

        iconImageView.contentMode = .scaleAspectFit

        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white

        let stackView = UIStackView(arrangedSubviews: [iconImageView, label])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center

        container.addSubview(stackView)
        view.addSubview(container)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 14),
            iconImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    private func createConstraints() {
        [container].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint
        ])
    }

    // MARK: - State Changes

    func setState(_ state: State, animated: Bool) {
        guard state != _state else { return }
        _state = state
        updateState(animated: animated)
    }

    private func updateState(animated: Bool) {
        guard isViewLoaded else { return }

        let isVisible: Bool
        switch state {
        case .hidden:
            isVisible = false
        case let .visible(color, text):
            isVisible = true
            configureBar(color: color, text: text)
        }

        let change = {
            self.heightConstraint.constant = isVisible ? Self.barHeight : 0
            self.container.alpha = isVisible ? 1 : 0
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.35, animations: change)
        } else {
            change()
        }
    }

    private func configureBar(color: UIColor, text: String) {
        container.backgroundColor = color.withAlphaComponent(0.2)
        label.text = text
        label.textColor = color

        let config = UIImage.SymbolConfiguration(
            pointSize: 12,
            weight: .semibold
        ).applying(UIImage.SymbolConfiguration(paletteColors: [color]))
        iconImageView.image = UIImage(systemName: "lock.fill", withConfiguration: config)
    }
}

// MARK: - Bar

extension ConfidentialityBarController: Bar {
    var weight: Float { 0 }
}
