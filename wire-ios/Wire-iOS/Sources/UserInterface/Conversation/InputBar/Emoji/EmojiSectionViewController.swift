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

// MARK: - EmojiSectionViewControllerDelegate

protocol EmojiSectionViewControllerDelegate: AnyObject {
    func sectionViewControllerDidSelectType(_ type: EmojiSectionType, scrolling: Bool)
}

// MARK: - EmojiSectionViewController

final class EmojiSectionViewController: UIViewController {
    // MARK: Lifecycle

    init(types: [EmojiSectionType]) {
        super.init(nibName: nil, bundle: nil)
        createButtons(types)

        setupViews()
        createConstraints()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
        self.selectedType = typesByButton.values.first
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var sectionDelegate: EmojiSectionViewControllerDelegate?

    func didSelectSection(_ type: EmojiSectionType) {
        guard let selected = selectedType, type != selected, !ignoreSelectionUpdates else { return }
        selectedType = type
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for sectionButton in sectionButtons {
            sectionButton.removeFromSuperview()
            view.addSubview(sectionButton)
        }

        createConstraints()
        for sectionButton in sectionButtons {
            sectionButton.hitAreaPadding = CGSize(width: 5, height: view.bounds.height / 2)
        }
    }

    // MARK: Private

    private var typesByButton = [IconButton: EmojiSectionType]()
    private var sectionButtons = [IconButton]()
    private let iconSize = StyleKitIcon.Size.tiny.rawValue
    private var ignoreSelectionUpdates = false

    private var selectedType: EmojiSectionType? {
        willSet(value) {
            guard let type = value else { return }
            for (button, sectionType) in typesByButton {
                button.isSelected = type == sectionType
            }
        }
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

    private func createSectionButton(for type: EmojiSectionType) -> IconButton {
        let button: IconButton = {
            let button = IconButton(style: .default)
            button.setIconColor(UIColor.from(scheme: .textDimmed, variant: .dark), for: .normal)
            button.setIconColor(.from(scheme: .textForeground, variant: .dark), for: .selected)
            button.setIconColor(.from(scheme: .iconHighlighted, variant: .dark), for: .highlighted)
            button.setBackgroundImageColor(.clear, for: .selected)
            button.setBorderColor(.clear, for: .normal)
            button.circular = false
            button.borderWidth = 0

            button.setIcon(type.icon, size: .tiny, for: .normal)

            return button
        }()

        button.addTarget(self, action: #selector(didTappButton), for: .touchUpInside)
        return button
    }

    @objc
    private func didTappButton(_ sender: IconButton) {
        guard let type = typesByButton[sender] else { return }
        sectionDelegate?.sectionViewControllerDidSelectType(type, scrolling: true)
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
            guard let button = sectionButtons.filter({ $0.frame.contains(location) }).first else { return }
            guard let type = typesByButton[button] else { return }
            sectionDelegate?.sectionViewControllerDidSelectType(type, scrolling: true)
            selectedType = type

        case .cancelled, .ended, .failed:
            ignoreSelectionUpdates = false

        @unknown default:
            break
        }
    }

    private func createConstraints() {
        let inset: CGFloat = 16
        let count = CGFloat(sectionButtons.count)
        let fullSpacing = (view.bounds.width - 2 * inset) - iconSize
        let padding: CGFloat = fullSpacing / (count - 1)

        var constraints = [NSLayoutConstraint]()

        for (idx, button) in sectionButtons.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false

            switch idx {
            case 0:
                constraints.append(button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset))
                constraints.append(view.heightAnchor.constraint(equalToConstant: iconSize + inset))

            default:
                let previous = sectionButtons[idx - 1]
                constraints.append(button.centerXAnchor.constraint(equalTo: previous.centerXAnchor, constant: padding))
            }

            constraints.append(button.topAnchor.constraint(equalTo: view.topAnchor))
        }

        NSLayoutConstraint.activate(constraints)
    }
}
