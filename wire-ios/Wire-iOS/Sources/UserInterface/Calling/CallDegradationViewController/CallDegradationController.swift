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
import WireDataModel

// MARK: - CallDegradationReason

enum CallDegradationReason: Equatable {
    case invalidCertificate
    case degradedUser(user: HashBoxUser?)
}

// MARK: - CallDegradationState

enum CallDegradationState: Equatable {
    case none
    case incoming(reason: CallDegradationReason)
    case outgoing(reason: CallDegradationReason)
    case terminating(reason: CallDegradationReason)
}

// MARK: - CallDegradationControllerDelegate

protocol CallDegradationControllerDelegate: AnyObject {
    func continueDegradedCall()
    func cancelDegradedCall()
}

// MARK: - CallDegradationController

final class CallDegradationController: UIViewController {
    // MARK: Internal

    weak var delegate: CallDegradationControllerDelegate?
    weak var targetViewController: UIViewController?
    var visibleAlertController: UIAlertController?

    var state: CallDegradationState = .none {
        didSet {
            guard oldValue != state else { return }

            updateState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewIsReady = true
        presentAlertIfNeeded()
    }

    // MARK: Fileprivate

    fileprivate func updateState() {
        switch state {
        case let .outgoing(reason: degradationReason):
            switch degradationReason {
            case .invalidCertificate:
                visibleAlertController = UIAlertController
                    .makeOutgoingDegradedMLSCall { [weak self] continueDegradedCall in
                        continueDegradedCall ? self?.delegate?.continueDegradedCall() : self?.delegate?
                            .cancelDegradedCall()
                    }

            case let .degradedUser(user: degradeduser):
                visibleAlertController = UIAlertController.makeOutgoingDegradedProteusCall(
                    degradedUser: degradeduser?.value
                ) { [weak self] continueDegradedCall in
                    if continueDegradedCall {
                        self?.delegate?.continueDegradedCall()
                    } else {
                        self?.delegate?.cancelDegradedCall()
                    }
                }
            }

        case .incoming, .none, .terminating:
            return
        }
        presentAlertIfNeeded()
    }

    // MARK: Private

    // Used to delay presentation of the alert controller until
    // the view is ready.
    private var viewIsReady = false

    private func presentAlertIfNeeded() {
        guard
            viewIsReady,
            let alertViewController = visibleAlertController,
            !alertViewController.isBeingPresented
        else { return }

        Log.calling.debug("Presenting alert about degraded call")
        targetViewController?.present(alertViewController, animated: !ProcessInfo.processInfo.isRunningTests)
    }
}
