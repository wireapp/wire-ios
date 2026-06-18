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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireLocators
import WireSyncEngine

final class UserStatusViewController: UIViewController {

    weak var delegate: UserStatusViewControllerDelegate?

    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private let options: UserStatusView.Options
    private let settings: Settings

    var userStatus = UserStatus() {
        didSet { (viewIfLoaded as? UserStatusDisplaying)?.userStatus = userStatus }
    }

    init(
        options: UserStatusView.Options,
        settings: Settings
    ) {
        self.options = options
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        if options.contains(.displayUpdateStatusButton) {
            let view = UserStatusSummaryView()
            view.userStatus = userStatus
            view.updateStatusHandler = { [weak self] in
                self?.presentAvailabilityPicker()
            }
            self.view = view
        } else {
            let view = UserStatusView(options: options)
            view.userStatus = userStatus
            view.tapHandler = { [weak self] _ in
                self?.presentAvailabilityPicker()
            }
            self.view = view
        }
    }

    private func presentAvailabilityPicker() {
        let viewController = UserStatusPickerViewController(currentAvailability: userStatus.availability, currentTextStatus: userStatus.textStatus) {
            [weak self] availability in
            guard let self else { return }

            selectAvailability(availability)
        }
        viewController.textStatusSaveHandler = { [weak self] textStatus in
            guard let self else { return }
            delegate?.userStatusViewController(self, didSelectTextStatus: textStatus)
        }

        if let navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: viewController)
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(
                action: UIAction { [weak self] _ in
                    self?.dismiss(animated: true)
                },
                accessibilityLabel: L10n.Localizable.General.close
            )
            present(navigationController, animated: true)
        }
    }

    private func selectAvailability(_ availability: Availability) {
        userStatus.availability = availability
        delegate?.userStatusViewController(self, didSelect: availability)
        feedbackGenerator.impactOccurred()

        if settings.shouldRemindUserWhenChanging(availability) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self else { return }

                let presenter = navigationController?.topViewController ?? self
                presenter.present(UIAlertController.availabilityExplanation(availability), animated: true)
            }
        }
    }
}

private protocol UserStatusDisplaying: AnyObject {
    var userStatus: UserStatus { get set }
}

extension UserStatusView: UserStatusDisplaying {}

private final class UserStatusSummaryView: UIView, UserStatusDisplaying {

    var updateStatusHandler: (() -> Void)?

    var userStatus = UserStatus() {
        didSet { updateStatusLabel() }
    }

    private let statusLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(style: .subline1, color: SemanticColors.Label.textDefault)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let updateStatusButton: SecondaryTextButton = {
        let button = SecondaryTextButton()
        button.accessibilityLabel = L10n.Localizable.Availability.Message.updateStatus
        button.setTitle(L10n.Localizable.Availability.Message.updateStatus, for: .normal)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [statusLabel, updateStatusButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        updateStatusButton.addTarget(self, action: #selector(updateStatusButtonTapped), for: .touchUpInside)
        addSubview(stackView)
        createConstraints()
        updateStatusLabel()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateStatusLabel() {
        let text = userStatus.textStatus ?? ""//userStatus.availability.localizedName
        statusLabel.text = text
        statusLabel.accessibilityLabel = L10n.Localizable.Availability.Message.currentStatus
        statusLabel.accessibilityValue = text
    }

    @objc
    private func updateStatusButtonTapped() {
        updateStatusHandler?()
    }
}

private final class UserStatusPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int, CaseIterable {
        case availability
        case customStatus
    }

    private let selectionHandler: (Availability) -> Void
    var textStatusSaveHandler: ((String?) -> Void)?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var currentAvailability: Availability
    private var customStatus = ""
    private var selectedEmoji: String?

    private let buttonHeight: CGFloat = 48
    private let buttonMargin: CGFloat = 16
    private var buttonBottomConstraint: NSLayoutConstraint?

    private let updateStatusButton: IconButton = {
        let button = IconButton(fontSpec: .normalSemiboldFont)
        button.applyStyle(.addParticipantsButtonStyle)
        button.setTitle(L10n.Localizable.Availability.Message.updateStatus, for: .normal)
        button.contentHorizontalAlignment = .center
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        return button
    }()

    init(
        currentAvailability: Availability,
        currentTextStatus: String? = nil,
        selectionHandler: @escaping (Availability) -> Void
    ) {
        self.currentAvailability = currentAvailability
        self.selectionHandler = selectionHandler
        let parsed = Self.parseTextStatus(currentTextStatus)
        self.selectedEmoji = parsed.emoji
        self.customStatus = parsed.text
        super.init(nibName: nil, bundle: nil)
    }

    private static func parseTextStatus(_ textStatus: String?) -> (emoji: String?, text: String) {
        guard let textStatus, let first = textStatus.unicodeScalars.first,
              first.properties.isEmoji, first.value > 0x238C else {
            return (nil, textStatus ?? "")
        }
        let emoji = String(textStatus.prefix(1))
        let rest = textStatus.dropFirst()
        let text = rest.hasPrefix(" ") ? String(rest.dropFirst()) : String(rest)
        return (emoji, text)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarTitle(L10n.Localizable.Availability.Message.setStatus)
        view.backgroundColor = SemanticColors.View.backgroundDefault
        createTableView()
        createConstraints()
        setupKeyboardObserver()
        updateStatusButton.addTarget(self, action: #selector(updateStatusButtonTapped), for: .touchUpInside)
    }

    private func createTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.keyboardDismissMode = .interactive
        tableView.clipsToBounds = true
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(
            AvailabilityDropdownCell.self,
            forCellReuseIdentifier: AvailabilityDropdownCell.reuseIdentifier
        )
        tableView.register(
            CustomStatusInputCell.self,
            forCellReuseIdentifier: CustomStatusInputCell.reuseIdentifier
        )
        tableView.contentInset.bottom = buttonHeight + buttonMargin * 2
        view.addSubview(tableView)
        view.addSubview(updateStatusButton)
    }

    private func createConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        updateStatusButton.translatesAutoresizingMaskIntoConstraints = false

        let bottomConstraint = updateStatusButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -buttonMargin
        )
        buttonBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            updateStatusButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: buttonMargin),
            updateStatusButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -buttonMargin),
            updateStatusButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            bottomConstraint
        ])
    }

    @objc private func updateStatusButtonTapped() {
        let text = customStatus.trimmingCharacters(in: .whitespaces)
        let emoji = selectedEmoji

        let combined: String
        if let emoji, !text.isEmpty {
            combined = "\(emoji) \(text)"
        } else if let emoji {
            combined = emoji
        } else if !text.isEmpty {
            combined = text
        } else {
            combined = " "
        }

        textStatusSaveHandler?(combined)
    }

    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardHeight = max(0, UIScreen.main.bounds.height - keyboardFrame.origin.y)
        let safeAreaBottom = view.safeAreaInsets.bottom
        let isKeyboardVisible = keyboardHeight > 0

        buttonBottomConstraint?.constant = isKeyboardVisible
            ? -(keyboardHeight - safeAreaBottom + buttonMargin)
            : -buttonMargin
        tableView.contentInset.bottom = isKeyboardVisible
            ? keyboardHeight - safeAreaBottom + buttonHeight + buttonMargin * 2
            : buttonHeight + buttonMargin * 2

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveRaw << 16)
        ) {
            self.view.layoutIfNeeded()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .availability:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AvailabilityDropdownCell.reuseIdentifier,
                for: indexPath
            ) as! AvailabilityDropdownCell
            cell.configure(selectedAvailability: currentAvailability) { [weak self] availability in
                guard let self, currentAvailability != availability else { return }

                currentAvailability = availability
                selectionHandler(availability)
                tableView.reloadSections(IndexSet(integer: Section.availability.rawValue), with: .none)
            }
            return cell

        case .customStatus:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CustomStatusInputCell.reuseIdentifier,
                for: indexPath
            ) as! CustomStatusInputCell
            cell.configure(
                text: customStatus,
                emoji: selectedEmoji,
                textChangeHandler: { [weak self] text in
                    self?.customStatus = text
                },
                emojiChangeHandler: { [weak self] emoji in
                    self?.selectedEmoji = emoji
                }
            )
            return cell

        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .availability:
            nil
        case .customStatus:
            L10n.Localizable.Availability.Message.customStatusSection
        case .none:
            nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .availability:
            footerText(for: currentAvailability)
        case .customStatus, .none:
            nil
        }
    }

    private func footerText(for availability: Availability) -> String {
        typealias AvailabilityReminderLocale = L10n.Localizable.Availability.Reminder

        switch availability {
        case .none:
            return AvailabilityReminderLocale.None.message
        case .available:
            return AvailabilityReminderLocale.Available.message
        case .busy:
            return AvailabilityReminderLocale.Busy.message
        case .away:
            return AvailabilityReminderLocale.Away.message
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = SemanticColors.Label.textSectionHeader
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = SemanticColors.Label.textSectionFooter
        }
    }
}

private final class AvailabilityDropdownCell: UITableViewCell {

    static let reuseIdentifier = "AvailabilityDropdownCell"

    private var selectedAvailability: Availability = .none
    private var selectionHandler: ((Availability) -> Void)?

    private let titleLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: SemanticColors.Label.textDefault
        )
        label.text = L10n.Localizable.Availability.Message.availabilitySection
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private lazy var dropdownButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.up.chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.baseForegroundColor = SemanticColors.Label.textDefault
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .font(for: .body1)
            return attributes
        }

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.contentHorizontalAlignment = .trailing
        button.showsMenuAsPrimaryAction = true
        button.titleLabel?.font = .font(for: .body1)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SemanticColors.View.backgroundUserCell
        contentView.backgroundColor = SemanticColors.View.backgroundUserCell
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(dropdownButton)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        selectedAvailability: Availability,
        selectionHandler: @escaping (Availability) -> Void
    ) {
        self.selectedAvailability = selectedAvailability
        self.selectionHandler = selectionHandler
        updateButton(for: selectedAvailability)
    }

    private func createConstraints() {
        [titleLabel, dropdownButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            dropdownButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            dropdownButton.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            dropdownButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dropdownButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    private func updateButton(for availability: Availability) {
        var configuration = dropdownButton.configuration ?? .plain()
        configuration.title = availability.localizedName
        dropdownButton.configuration = configuration
        dropdownButton.accessibilityLabel = L10n.Localizable.Availability.Message.availabilitySection
        dropdownButton.accessibilityValue = availability.localizedName
        dropdownButton.menu = UIMenu(children: availabilityActions())
    }

    private func availabilityActions() -> [UIAction] {
        Availability.allCases.map { availability in
            UIAction(
                title: availability.localizedName,
                image: availability.iconType?.makeImage(
                    size: .tiny,
                    color: AvailabilityStringBuilder.color(for: availability)
                ),
                state: availability == selectedAvailability ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }

                selectedAvailability = availability
                updateButton(for: availability)
                selectionHandler?(availability)
            }
        }
    }
}

private final class CustomStatusInputCell: UITableViewCell {

    static let reuseIdentifier = "CustomStatusInputCell"

    private var textChangeHandler: ((String) -> Void)?
    private var emojiChangeHandler: ((String?) -> Void)?
    private var selectedEmoji: String?
    private var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.accessibilityLabel = L10n.Localizable.Availability.Message.customStatusSection
        textField.adjustsFontForContentSizeCategory = true
        textField.autocapitalizationType = .sentences
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.font = .font(for: .body1)
        textField.placeholder = L10n.Localizable.Availability.Message.customStatusPlaceholder
        textField.textColor = SemanticColors.Label.textDefault
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.delegate = self
        return textField
    }()

    private lazy var emojiButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "face.smiling")
        config.baseForegroundColor = SemanticColors.Label.textDefault
        config.background.cornerRadius = 15
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(emojiButtonTapped), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SemanticColors.View.backgroundUserCell
        contentView.backgroundColor = SemanticColors.View.backgroundUserCell
        selectionStyle = .none
        contentView.addSubview(textField)
        textField.leftView = emojiButton
        textField.leftViewMode = .always
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        text: String,
        emoji: String? = nil,
        textChangeHandler: @escaping (String) -> Void,
        emojiChangeHandler: ((String?) -> Void)? = nil
    ) {
        self.textChangeHandler = textChangeHandler
        self.emojiChangeHandler = emojiChangeHandler

        if textField.text != text {
            textField.text = text
        }

        if let emoji {
            selectedEmoji = emoji
            var config = emojiButton.configuration ?? .plain()
            config.image = nil
            config.title = emoji
            emojiButton.configuration = config
        }
    }

    private func createConstraints() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textField.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    @objc private func emojiButtonTapped() {
        let picker = CompleteReactionPickerViewController(selectedReactions: [])
        picker.delegate = self
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        parentViewController?.present(nav, animated: true)
    }

    @objc
    private func textFieldDidChange() {
        let text = textField.text ?? ""
        textChangeHandler?(text)

        guard selectedEmoji == nil else { return }
        var config = emojiButton.configuration ?? .plain()
        if text.isEmpty {
            selectedEmoji = nil
            emojiChangeHandler?(nil)
            config.image = UIImage(systemName: "face.smiling")
            config.title = nil
        } else {
            selectedEmoji = "💬"
            emojiChangeHandler?("💬")
            config.image = nil
            config.title = "💬"
        }
        emojiButton.configuration = config
    }
}

extension CustomStatusInputCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        selectedEmoji = nil
        emojiChangeHandler?(nil)
        var config = emojiButton.configuration ?? .plain()
        config.title = nil
        config.image = UIImage(systemName: "face.smiling")
        emojiButton.configuration = config
        return true
    }
}

extension CustomStatusInputCell: EmojiPickerViewControllerDelegate {
    func emojiPickerDidSelectEmoji(_ emoji: Emoji) {
        selectedEmoji = emoji.value
        emojiChangeHandler?(emoji.value)
        var config = emojiButton.configuration ?? .plain()
        config.image = nil
        config.title = emoji.value
        emojiButton.configuration = config
        parentViewController?.dismiss(animated: true)
    }

    func emojiPickerDeleteTapped() {}
}
