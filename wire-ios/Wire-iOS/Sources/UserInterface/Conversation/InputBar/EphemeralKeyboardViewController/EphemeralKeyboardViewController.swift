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
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Allow conversation argument is nil for testing
    ///
    /// - Parameter conversation: nil for testing only
    init(conversation: ZMConversation!) {
        self.conversation = conversation
        if Bundle.developerModeEnabled {
            self.timeouts = MessageDestructionTimeoutValue.all + [nil]
        } else {
            self.timeouts = MessageDestructionTimeoutValue.all
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    weak var delegate: EphemeralKeyboardViewControllerDelegate?

    let titleLabel = DynamicFontLabel(
        text: L10n.Localizable.Input.Ephemeral.title,
        fontSpec: .mediumSemiboldFont,
        color: SemanticColors.Label.textDefault
    )
    var pickerFont: UIFont? = .normalSemiboldFont
    var pickerColor: UIColor? = SemanticColors.Label.textDefault
    var separatorColor: UIColor? = SemanticColors.View.backgroundSeparatorCell

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
        guard let index = timeouts.firstIndex(of: currentTimeout) else {
            return
        }
        picker.selectRow(index, inComponent: 0, animated: false)
    }

    // MARK: - Methods

    func dismissKeyboardIfNeeded() {
        delegate?.ephemeralKeyboardWantsToBeDismissed(self)
    }

    // MARK: Fileprivate

    fileprivate let timeouts: [MessageDestructionTimeoutValue?]

    fileprivate func displayCustomPicker() {
        delegate?.ephemeralKeyboardWantsToBeDismissed(self)

        UIAlertController
            .requestCustomTimeInterval(
                over: UIApplication.shared
                    .topmostViewController(onlyFullScreen: true)!
            ) { [weak self] result in

                guard let self else {
                    return
                }

                switch result {
                case let .success(value):
                    delegate?.ephemeralKeyboard(self, didSelectMessageTimeout: value)
                default:
                    break
                }
            }
    }

    // MARK: Private

    private let conversation: ZMConversation!
    private let picker = PickerView()

    // MARK: - Setup views and constraints

    private func setupViews() {
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        picker.tintColor = .red
        picker.selectorColor = separatorColor
        picker.didTapViewClosure = dismissKeyboardIfNeeded

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
            picker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }
}

// MARK: UIPickerViewDelegate, UIPickerViewDataSource

extension EphemeralKeyboardViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        35
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        timeouts.count
    }

    func pickerView(
        _ pickerView: UIPickerView,
        attributedTitleForRow row: Int,
        forComponent component: Int
    ) -> NSAttributedString? {
        guard let font = pickerFont, let color = pickerColor else {
            return nil
        }
        let timeout = timeouts[row]
        if let actualTimeout = timeout, let title = actualTimeout.displayString {
            return NSAttributedString(string: title, attributes: [.font: font, .foregroundColor: color])
        } else {
            return NSAttributedString(string: "Custom", attributes: [.font: font, .foregroundColor: color])
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let timeout = timeouts[row]

        if let actualTimeout = timeout {
            delegate?.ephemeralKeyboard(self, didSelectMessageTimeout: actualTimeout.rawValue)
        } else {
            displayCustomPicker()
        }
    }
}
