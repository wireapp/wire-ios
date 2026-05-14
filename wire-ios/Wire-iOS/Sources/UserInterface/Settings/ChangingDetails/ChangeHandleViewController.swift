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
import WireDesign
import WireReusableUIComponents
import WireSettingsUI
import WireSyncEngine

final class ChangeHandleViewControllerBuilder {

    private let useTypeIntrinsicSizeTableView: Bool
    private let settingsCoordinator: AnySettingsCoordinator
    private let isFederationEnabled: Bool
    private let userSession: UserSession
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        isFederationEnabled: Bool,
        userSession: UserSession,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.useTypeIntrinsicSizeTableView = useTypeIntrinsicSizeTableView
        self.settingsCoordinator = settingsCoordinator
        self.isFederationEnabled = isFederationEnabled
        self.userSession = userSession
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    func build() -> UIViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation()
        }

        return buildLegacy()
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .changeHandle,
            isKMPImplementationAvailable: false
        )
    }

    private func buildKMPViewModelImplementation() -> UIViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy()
    }

    private func buildLegacy() -> UIViewController {
        ChangeHandleViewController(
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator,
            isFederationEnabled: isFederationEnabled,
            userSession: userSession
        )
    }
}

private extension UIView {

    func wiggle() {
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.duration = 0.3
        animation.isAdditive = true
        animation.values = [0, 4, -4, 2, 0]
        animation.keyTimes = [0, 0.166, 0.5, 0.833, 1]
        layer.add(animation, forKey: "wiggle-animation")
    }

}

protocol ChangeHandleTableViewCellDelegate: AnyObject {
    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool
    func tableViewCellDidChangeText(cell: ChangeHandleTableViewCell, text: String)
}

final class ChangeHandleTableViewCell: UITableViewCell, UITextFieldDelegate {

    weak var delegate: ChangeHandleTableViewCellDelegate?
    let prefixLabel: UILabel = {
        let label = UILabel()
        label.font = .normalSemiboldFont
        label.textColor = SemanticColors.Label.textDefault

        return label
    }()

    let handleTextField: ContextMenuControllableUITextField = {
        let textField = ContextMenuControllableUITextField(
            frame: .zero,
            isContextMenuAllowed: SecurityFlags.clipboard.isEnabled
        )
        textField.font = .normalFont
        textField.textColor = SemanticColors.Label.textDefault

        return textField
    }()

    let domainLabel: UILabel = {
        let label = UILabel()
        label.font = .normalSemiboldFont
        label.textColor = .gray
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()

        setupStyle()
    }

    func setupStyle() {
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        handleTextField.delegate = self
        handleTextField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        handleTextField.autocapitalizationType = .none
        handleTextField.accessibilityLabel = "handleTextField"
        handleTextField.autocorrectionType = .no
        handleTextField.spellCheckingType = .no
        handleTextField.textAlignment = .right
        prefixLabel.text = "@"
        [prefixLabel, handleTextField, domainLabel].forEach(addSubview)
    }

    private func createConstraints() {
        [prefixLabel, handleTextField, domainLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            prefixLabel.topAnchor.constraint(equalTo: topAnchor),
            prefixLabel.widthAnchor.constraint(equalToConstant: 16),
            prefixLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            prefixLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            prefixLabel.trailingAnchor.constraint(equalTo: handleTextField.leadingAnchor, constant: -4),
            handleTextField.topAnchor.constraint(equalTo: topAnchor),
            handleTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
            handleTextField.trailingAnchor.constraint(equalTo: domainLabel.leadingAnchor, constant: -4),
            domainLabel.topAnchor.constraint(equalTo: topAnchor),
            domainLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            domainLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
    }

    func performWiggleAnimation() {
        [handleTextField, prefixLabel].forEach {
            $0.wiggle()
        }
    }

    // MARK: - UITextField

    @objc
    func editingChanged(textField: UITextField) {
        let lowercase = textField.text?.lowercased() ?? ""
        textField.text = lowercase
        delegate?.tableViewCellDidChangeText(cell: self, text: lowercase)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let delegate else { return false }
        let current = (textField.text ?? "") as NSString
        let replacement = current.replacingCharacters(in: range, with: string)
        if delegate.tableViewCell(cell: self, shouldAllowEditingText: replacement) {
            return true
        }

        performWiggleAnimation()
        return false
    }
}

final class ChangeHandleViewController: SettingsBaseTableViewController {
    private typealias HandleChange = L10n.Localizable.Self.Settings.AccountSection.Handle.Change

    var footerFont: UIFont = .smallFont
    private var viewModel: ChangeHandleViewModel
    private var footerLabel = UILabel()
    fileprivate weak var userProfile: UserProfile?
    private var observerToken: Any?
    var popOnSuccess = true

    private lazy var activityIndicator = BlockingActivityIndicator(view: view)

    convenience init(
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        isFederationEnabled: Bool,
        userSession: UserSession
    ) {
        let user = SelfUser.provider?.providedSelfUser
        self.init(
            state: HandleChangeState(currentHandle: user?.handle ?? nil, newHandle: nil, availability: .unknown),
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator,
            isFederationEnabled: isFederationEnabled,
            userSession: userSession
        )
    }

    convenience init(
        suggestedHandle handle: String,
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        isFederationEnabled: Bool,
        userSession: UserSession
    ) {
        self.init(
            state: .init(currentHandle: nil, newHandle: handle, availability: .unknown),
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator,
            isFederationEnabled: isFederationEnabled,
            userSession: userSession
        )
        setupViews()
        checkAvailability(of: handle)
    }

    /// Used to inject a specific `HandleChangeState` in tests. See `ChangeHandleViewControllerTests`.
    init(
        state: HandleChangeState,
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        isFederationEnabled: Bool,
        userSession: UserSession
    ) {
        self.viewModel = ChangeHandleViewModel(
            state: state,
            federationEnabled: isFederationEnabled,
            domainString: SelfUser.provider?.providedSelfUser.domainString
        )
        super.init(
            style: .grouped,
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator
        )

        self.userProfile = userSession.userProfile
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationBar()
        updateUI()
        observerToken = userProfile?.add(observer: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observerToken = nil
    }

    private func setupViews() {
        view.backgroundColor = .clear
        ChangeHandleTableViewCell.register(in: tableView)
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = SemanticColors.View.backgroundSeparatorCell
        footerLabel.numberOfLines = 0
        updateUI()
    }

    func setupNavigationBar() {
        setupNavigationBarTitle(HandleChange.title)
        let saveButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: HandleChange.save,
            action: UIAction { [weak self] _ in
                self?.saveButtonTapped()
            }
        )

        saveButtonItem.tintColor = .accent()
        navigationItem.rightBarButtonItem = saveButtonItem

    }

    func saveButtonTapped() {
        guard let handleToSet = viewModel.handleToSave else { return }
        userProfile?.requestSettingHandle(handle: handleToSet)
        activityIndicator.start()
    }

    fileprivate var attributedFooterTitle: NSAttributedString? {
        let infoText = HandleChange.footer.attributedString && SemanticColors.Label.textSectionFooter
        let alreadyTakenText = HandleChange.Footer.unavailable && SemanticColors.Label.textErrorDefault
        let prefix = viewModel.displayModel.availability == .taken ? alreadyTakenText + "\n\n" : "\n\n".attributedString
        return (prefix + infoText) && footerFont
    }

    private func updateFooter() {
        footerLabel.attributedText = attributedFooterTitle
        let size = footerLabel.sizeThatFits(CGSize(width: view.frame.width - 32, height: UIView.noIntrinsicMetric))
        footerLabel.frame = CGRect(origin: CGPoint(x: 16, y: 0), size: size)
        tableView.tableFooterView = footerLabel
    }

    private func updateNavigationItem() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.displayModel.isSaveEnabled
    }

    fileprivate func updateUI() {
        updateNavigationItem()
        updateFooter()
    }

    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChangeHandleTableViewCell.zm_reuseIdentifier,
            for: indexPath
        ) as! ChangeHandleTableViewCell
        let displayModel = viewModel.displayModel
        cell.delegate = self
        cell.handleTextField.text = displayModel.displayHandle
        cell.handleTextField.becomeFirstResponder()
        cell.domainLabel.isHidden = displayModel.isDomainHidden

        if SelfUser.provider?.providedSelfUser != nil {
            cell.domainLabel.text = displayModel.domainText
        } else {
            assertionFailure("expected available 'user'!")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }
}

extension ChangeHandleViewController: ChangeHandleTableViewCellDelegate {

    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool {
        // The edit is allowed unless the new handle contains invalid characters or is too long.
        viewModel.shouldAllowEditingText(text)
    }

    func tableViewCellDidChangeText(cell: ChangeHandleTableViewCell, text: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        switch viewModel.updateText(text) {
        case .checkAvailability(let handle):
            perform(#selector(checkAvailability), with: handle, afterDelay: 0.2)
        case .none:
            break
        }

        updateUI()
    }

    @objc
    fileprivate func checkAvailability(of handle: String) {
        userProfile?.requestCheckHandleAvailability(handle: handle)
    }

}

extension ChangeHandleViewController: UserProfileUpdateObserver {

    func didCheckAvailiabilityOfHandle(handle: String, available: Bool) {
        guard viewModel.didCheckAvailability(of: handle, available: available) else { return }
        updateUI()
    }

    func didFailToCheckAvailabilityOfHandle(handle: String) {
        guard viewModel.didFailToCheckAvailability(of: handle) else { return }
        updateUI()
    }

    func didSetHandle() {
        activityIndicator.stop()
        switch viewModel.didSetHandle(popOnSuccess: popOnSuccess) {
        case .pop:
            _ = navigationController?.popViewController(animated: true)
        case .none:
            break
        }
    }

    func didFailToSetHandle() {
        presentFailureAlert()
        activityIndicator.stop()
    }

    func didFailToSetHandleBecauseExisting() {
        viewModel.didFailToSetHandleBecauseExisting()
        updateUI()
        activityIndicator.stop()
    }

    private func presentFailureAlert() {
        let failureAlert = viewModel.failureAlert
        let alert = UIAlertController(
            title: failureAlert.title,
            message: failureAlert.message,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: failureAlert.buttonTitle, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
