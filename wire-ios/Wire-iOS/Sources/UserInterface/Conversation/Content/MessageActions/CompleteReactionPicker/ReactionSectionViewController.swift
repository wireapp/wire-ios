//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireCommonComponents

final class ReactionSectionViewController: UIViewController {

    private var typesByButton = [ReactionCategoryButton: EmojiSectionType]()
    private var sectionButtons = [ReactionCategoryButton]()
    private let iconSize = StyleKitIcon.Size.tiny.rawValue
    private var ignoreSelectionUpdates = false

    private var selectedType: EmojiSectionType? {
        willSet(value) {
            guard let type = value else { return }
            typesByButton.forEach { button, sectionType in
                button.isSelected = type == sectionType
            }
        }
    }

    weak var sectionDelegate: EmojiSectionViewControllerDelegate?

    init(types: [EmojiSectionType]) {
        super.init(nibName: nil, bundle: nil)
        createButtons(types)

        setupViews()
        createConstraints()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
        selectedType = typesByButton.values.first
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createButtons(_ types: [EmojiSectionType]) {
        sectionButtons = types.map(createSectionButton)
        zip(types, sectionButtons).forEach { (type, button) in
            typesByButton[button] = type
        }
    }

    private func setupViews() {
        sectionButtons.forEach(view.addSubview)
    }

    private func createSectionButton(for type: EmojiSectionType) -> ReactionCategoryButton {
        let button: ReactionCategoryButton = {
            let button = ReactionCategoryButton()
            let image = type.imageAsset.image
            button.setImage(image, for: .normal)

            return button
        }()

        button.addTarget(self, action: #selector(didTappButton), for: .touchUpInside)
        return button
    }

    func didSelectSection(_ type: EmojiSectionType) {
        guard let selected = selectedType, type != selected, !ignoreSelectionUpdates else { return }
        selectedType = type
    }

    @objc private func didTappButton(_ sender: ReactionCategoryButton) {
        guard let type = typesByButton[sender] else { return }
        sectionDelegate?.sectionViewController(self, didSelect: type, scrolling: false)
    }

    @objc private func didPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .possible: break
        case .began:
            ignoreSelectionUpdates = true
            fallthrough
        case .changed:
            let location = recognizer.location(in: view)
            guard let button = sectionButtons.filter({ $0.frame.contains(location) }).first else { return }
            guard let type = typesByButton[button] else { return }
            sectionDelegate?.sectionViewController(self, didSelect: type, scrolling: true)
            selectedType = type
        case .ended, .failed, .cancelled:
            ignoreSelectionUpdates = false
        @unknown default:
            break
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sectionButtons.forEach {
            $0.removeFromSuperview()
            view.addSubview($0)
        }

        createConstraints()
    }

    private func createConstraints() {

        let inset: CGFloat = 16
        let count = CGFloat(sectionButtons.count)
        let fullSpacing = (view.bounds.width - 2 * inset) - iconSize
        let padding: CGFloat = fullSpacing / (count - 1)

        var constraints = [NSLayoutConstraint]()

        sectionButtons.enumerated().forEach { idx, button in

            button.translatesAutoresizingMaskIntoConstraints = false

            switch idx {
            case 0:
                constraints.append(button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset))
            default:
                let previous = sectionButtons[idx - 1]
                constraints.append(button.centerXAnchor.constraint(equalTo: previous.centerXAnchor, constant: padding))
            }

            constraints.append(button.topAnchor.constraint(equalTo: view.topAnchor))
            constraints.append(button.bottomAnchor.constraint(equalTo: view.bottomAnchor))
            constraints.append(button.widthAnchor.constraint(equalToConstant: padding - 8.0))
        }

        NSLayoutConstraint.activate(constraints)
    }

}
