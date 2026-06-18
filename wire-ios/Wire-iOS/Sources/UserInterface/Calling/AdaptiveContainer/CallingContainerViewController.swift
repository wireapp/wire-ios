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

import SwiftUI
import UIKit
import WireDataModel

protocol ActiveCallViewControllerDelegate: AnyObject {
    func activeCallViewControllerDidDisappear(
        _ activeCallViewController: UIViewController,
        for conversation: ZMConversation?
    )
}

final class CallingContainerViewController: UIHostingController<CallingContainerView> {

    weak var delegate: ActiveCallViewControllerDelegate?

    private let viewModel: CallingContainerViewModel
    private let callDegradationController = CallDegradationController()

    init(viewModel: CallingContainerViewModel) {
        self.viewModel = viewModel
        super.init(rootView: CallingContainerView(viewModel: viewModel))

        viewModel.onHideCallView = { [weak self] in
            guard let self else { return }
            delegate?.activeCallViewControllerDidDisappear(self, for: viewModel.voiceChannel.conversation)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.startObserving()
        setupCallDegradationController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.callViewController?.reloadGrid()
    }

    private func setupCallDegradationController() {
        addChild(callDegradationController)
        view.addSubview(callDegradationController.view)
        callDegradationController.view.fitIn(view: view)
        callDegradationController.didMove(toParent: self)
        callDegradationController.targetViewController = self
        callDegradationController.delegate = self
    }
}

// MARK: - CallDegradationControllerDelegate

extension CallingContainerViewController: CallDegradationControllerDelegate {

    func continueDegradedCall() {
        viewModel.callViewController?.callingActionsViewPerformAction(.continueDegradedCall)
    }

    func cancelDegradedCall() {
        viewModel.callViewController?.callingActionsViewPerformAction(.terminateDegradedCall)
    }
}
