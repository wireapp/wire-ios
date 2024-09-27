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
import WireCommonComponents
import WireDesign

final class ReactionSectionViewController: UIViewController {
    private var typesByButton = [ReactionCategoryButton: EmojiSectionType]()
    private var sectionButtons = [ReactionCategoryButton]()
    private let iconSize = StyleKitIcon.Size.tiny.rawValue
    private var ignoreSelectionUpdates = false

    private var selectedType: EmojiSectionType? {
        willSet(value) {
            guard isEnabled, let type = value else { return }
            for (button, sectionType) in typesByButton {
                button.isSelected = type == sectionType
            }
        }
    }

    var isEnabled = true {
        didSet {
            panGestureRecognizer.isEnabled = isEnabled
            for (button, sectionType) in typesByButton {
                button.isEnabled = isEnabled
                button.isSelected = isEnabled && sectionType == selectedType
            }
        }
    }

    private let types: [EmojiSectionType]
    private let panGestureRecognizer = UIPanGestureRecognizer(
        target: ReactionSectionViewController.self,
        action: #selector(didPan)
    )
    weak var sectionDelegate: EmojiSectionViewControllerDelegate?

    init(types: [EmojiSectionType]) {
        self.types = types
        super.init(nibName: nil, bundle: nil)
        createButtons(types)

        setupViews()
        createConstraints()
        view.addGestureRecognizer(panGestureRecognizer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let firstType = types.first else { return }
        selectedType = firstType
    }

    private func createButtons(_ types: [EmojiSectionType]) {
        sectionButtons = types.map(createSectionButton)
        for (type, button) in zip(types, sectionButtons) {
            typesByButton[button] = type
        }
    }

    private func setupViews() {
        sectionButtons.forEach(view.addSubview)
    }

    private func createSectionButton(for type: EmojiSectionType) -> ReactionCategoryButton {
        let button: ReactionCategoryButton = {
            let button = ReactionCategoryButton()
            let image = UIImage(resource: type.imageAsset)
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

    @objc
    private func didTappButton(_ sender: ReactionCategoryButton) {
        guard let type = typesByButton[sender] else { return }
        sectionDelegate?.sectionViewControllerDidSelectType(type, scrolling: false)
    }

    @objc
    private func didPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .possible: break

        case .began:
            ignoreSelectionUpdates = true
            fallthrough

        case .changed:
            let location = recognizer.location(in: view)
            guard let button = sectionButtons.filter({ $0.frame.contains(location) }).first,
                  let type = typesByButton[button]
            else { return }
            sectionDelegate?.sectionViewControllerDidSelectType(type, scrolling: true)
            selectedType = type

        case .ended, .failed, .cancelled:
            ignoreSelectionUpdates = false

        @unknown default:
            break
        }
    }

    private func createConstraints() {
        let count = CGFloat(sectionButtons.count)
        let fullSpacing = view.bounds.width - iconSize
        let padding: CGFloat = fullSpacing / count

        var constraints = [NSLayoutConstraint]()

        for (idx, button) in sectionButtons.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false

            switch idx {
            case 0:
                constraints.append(button.leadingAnchor.constraint(equalTo: view.leadingAnchor))
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
