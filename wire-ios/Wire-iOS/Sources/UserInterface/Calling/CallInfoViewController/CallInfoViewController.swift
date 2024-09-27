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
import WireSyncEngine

// MARK: - CallInfoViewControllerDelegate

protocol CallInfoViewControllerDelegate: AnyObject {
    func infoViewController(_ viewController: CallInfoViewController, perform action: CallAction)
}

// MARK: - CallInfoViewControllerInput

protocol CallInfoViewControllerInput: CallActionsViewInputType, CallStatusViewInputType {
    var accessoryType: CallInfoViewControllerAccessoryType { get }
    var degradationState: CallDegradationState { get }
    var videoPlaceholderState: CallVideoPlaceholderState { get }
    var disableIdleTimer: Bool { get }
}

// Workaround to make the protocol equatable, it might be possible to conform CallInfoConfiguration
// to Equatable with Swift 4.1 and conditional conformances. Right now we would have to make
// the `CallInfoRootViewController` generic to work around the `Self` requirement of
// `Equatable` which we want to avoid.
extension CallInfoViewControllerInput {
    func isEqual(toConfiguration other: CallInfoViewControllerInput) -> Bool {
        accessoryType == other.accessoryType &&
            degradationState == other.degradationState &&
            videoPlaceholderState == other.videoPlaceholderState &&
            permissions == other.permissions &&
            disableIdleTimer == other.disableIdleTimer &&
            canToggleMediaType == other.canToggleMediaType &&
            isMuted == other.isMuted &&
            mediaState == other.mediaState &&
            appearance == other.appearance &&
            isVideoCall == other.isVideoCall &&
            state == other.state &&
            isConstantBitRate == other.isConstantBitRate &&
            title == other.title &&
            cameraType == other.cameraType &&
            userEnabledCBR == other.userEnabledCBR &&
            callState.isEqual(toCallState: other.callState) &&
            videoGridPresentationMode == other.videoGridPresentationMode &&
            allowPresentationModeUpdates == other.allowPresentationModeUpdates &&
            isForcedCBR == other.isForcedCBR &&
            classification == other.classification
    }
}

// MARK: - CallInfoViewController

final class CallInfoViewController: UIViewController, CallActionsViewDelegate, CallAccessoryViewControllerDelegate {
    // MARK: Lifecycle

    init(
        configuration: CallInfoViewControllerInput,
        selfUser: UserType,
        userSession: UserSession
    ) {
        self.configuration = configuration

        self.statusViewController = CallStatusViewController(configuration: configuration)

        self.accessoryViewController = CallAccessoryViewController(
            configuration: configuration,
            selfUser: selfUser,
            userSession: userSession
        )

        super.init(nibName: nil, bundle: nil)
        accessoryViewController.delegate = self
        actionsView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: CallInfoViewControllerDelegate?

    var configuration: CallInfoViewControllerInput {
        didSet {
            updateState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateNavigationItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.didSizeClassChange(from: previousTraitCollection) else { return }

        updateAccessoryView()
    }

    func callActionsView(_ callActionsView: CallActionsView, perform action: CallAction) {
        delegate?.infoViewController(self, perform: action)
    }

    func callAccessoryViewControllerDidSelectShowMore(viewController: CallAccessoryViewController) {
        delegate?.infoViewController(self, perform: .showParticipantsList)
    }

    // MARK: Private

    private let stackView = UIStackView(axis: .vertical)
    private let statusViewController: CallStatusViewController
    private let accessoryViewController: CallAccessoryViewController
    private let actionsView = CallActionsView()

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16

        addChild(statusViewController)
        [statusViewController.view, accessoryViewController.view, actionsView].forEach(stackView.addArrangedSubview)
        statusViewController.didMove(toParent: self)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: safeTopAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuideOrFallback.bottomAnchor, constant: -25),
            statusViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),

            actionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            accessoryViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
    }

    private func updateNavigationItem() {
        let minimizeItem = UIBarButtonItem(
            icon: .downArrow,
            target: self,
            action: #selector(minimizeCallOverlay)
        )

        minimizeItem.accessibilityLabel = L10n.Localizable.Call.Actions.Label.minimizeCall
        minimizeItem.accessibilityIdentifier = "CallDismissOverlayButton"

        navigationItem.leftBarButtonItem = minimizeItem
    }

    private func updateAccessoryView() {
        let isHidden = traitCollection.verticalSizeClass == .compact && !configuration.callState.isConnected

        accessoryViewController.view.isHidden = isHidden
    }

    private func updateState() {
        Log.calling.debug("updating info controller with state: \(configuration)")
        actionsView.update(with: configuration)
        statusViewController.configuration = configuration
        accessoryViewController.configuration = configuration
        updateAccessoryView()
    }

    // MARK: - Actions + Delegates

    @objc
    private func minimizeCallOverlay(_: UIBarButtonItem) {
        delegate?.infoViewController(self, perform: .minimizeOverlay)
    }
}
