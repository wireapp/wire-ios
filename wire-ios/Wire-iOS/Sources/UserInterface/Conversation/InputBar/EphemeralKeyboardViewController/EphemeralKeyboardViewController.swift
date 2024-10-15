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
import WireDataModel
import WireDesign

// MARK: - EphemeralKeyboardViewControllerDelegate

protocol EphemeralKeyboardViewControllerDelegate: AnyObject {
    func ephemeralKeyboardWantsToBeDismissed(_ keyboard: EphemeralKeyboardViewController)

    func ephemeralKeyboard(
        _ keyboard: EphemeralKeyboardViewController,
        didSelectMessageTimeout timeout: TimeInterval
    )
}

// MARK: - EphemeralKeyboardViewController

final class EphemeralKeyboardViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: EphemeralKeyboardViewControllerDelegate?

    private let timeouts = MessageDestructionTimeoutValue.all

    private let titleLabel = DynamicFontLabel(
        text: L10n.Localizable.Input.Ephemeral.title,
        style: .body1,
        color: SemanticColors.Label.textDefault
    )

    private let pickerFont: UIFont = .normalSemiboldFont
    private let pickerColor: UIColor = SemanticColors.Label.textDefault
    private let separatorColor: UIColor = SemanticColors.View.backgroundSeparatorCell

    private let conversation: ZMConversation!
    private let picker = PickerView()

    // MARK: - Initialization
    /// Allow conversation argument is nil for testing
    ///
    /// - Parameter conversation: nil for testing only
    init(conversation: ZMConversation!) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()

        view.backgroundColor = SemanticColors.View.backgroundDefault
        UIAccessibility.post(notification: .layoutChanged, argument: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let currentTimeout = conversation.messageDestructionTimeoutValue(for: .selfUser)
        guard let index = timeouts.firstIndex(of: currentTimeout) else { return }
        picker.selectRow(index, inComponent: 0, animated: false)
    }

    // MARK: - Setup views and constraints
    private func setupViews() {
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        picker.tintColor = .red
        picker.selectorColor = separatorColor
        picker.didTapViewClosure = { [weak self] in
            self?.dismissKeyboardIfNeeded()
        }

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        [titleLabel, picker].forEach(view.addSubview)
    }

    private func createConstraints() {
        [picker, titleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            picker.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            picker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            picker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - Methods
    func dismissKeyboardIfNeeded() {
        delegate?.ephemeralKeyboardWantsToBeDismissed(self)
    }

}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource

extension EphemeralKeyboardViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeouts.count
    }

    func pickerView(
        _ pickerView: UIPickerView,
        attributedTitleForRow row: Int,
        forComponent component: Int
    ) -> NSAttributedString? {
        let timeout = timeouts[row]
        let displayString = timeout.displayString
        requireInternal(displayString != nil, "Missing displayString for \(timeout)")

        let title = displayString ?? "Unknown"
        return NSAttributedString(string: title, attributes: [.font: pickerFont, .foregroundColor: pickerColor])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.ephemeralKeyboard(self, didSelectMessageTimeout: timeouts[row].rawValue)
    }

}
