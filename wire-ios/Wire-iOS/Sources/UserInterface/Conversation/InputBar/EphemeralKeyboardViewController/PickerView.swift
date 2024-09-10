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

// MARK: - Picker View

/// This class is a workaround to make the selector color
/// of a `UIPickerView` changeable. It relies on the height of the selector
/// views, which means that the behaviour could break in future iOS updates.

final class PickerView: UIPickerView, UIGestureRecognizerDelegate {

    // MARK: - Properties

    var selectorColor: UIColor?
    var tapRecognizer: UIGestureRecognizer! = nil
    var didTapViewClosure: (() -> Void)?

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapRecognizer.delegate = self
        addGestureRecognizer(tapRecognizer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews where subview.bounds.height <= 1.0 {
            subview.backgroundColor = selectorColor
        }
    }

    // MARK: - Actions

    @objc
    func didTapView(sender: UIGestureRecognizer) {
        guard recognizerInSelectedRow(sender) else { return }
        didTapViewClosure?()
    }

    /// Used to determine if the recognizers touches are in the area
    /// of the selected row of the `UIPickerView`, this is done by asking the
    /// delegate for the rowHeight and using it to calculate the rect
    /// of the center (selected) row.
    private func recognizerInSelectedRow(_ recognizer: UIGestureRecognizer) -> Bool {
        guard selectedRow(inComponent: 0) != -1 else { return false }
        guard let height = delegate?.pickerView?(self, rowHeightForComponent: 0) else { return false }
        let rect = bounds.insetBy(dx: 0, dy: bounds.midY - height / 2)
        let location = recognizer.location(in: self)
        return rect.contains(location)
    }

    // MARK: - UIGestureRecognizerDelegate

    // We want the tap gesture recognizer to fire when the selected row is tapped,
    // but need to make sure the scrolling behavior and taps outside the selected row still
    // get propagated (otherwise the scroll-to behavior would break when tapping on another row) etc.

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer == tapRecognizer && recognizerInSelectedRow(gestureRecognizer)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return otherGestureRecognizer == tapRecognizer && recognizerInSelectedRow(gestureRecognizer)
    }
}
