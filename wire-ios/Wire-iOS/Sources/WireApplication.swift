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

import WireCommonComponents
import WireSyncEngine
import Combine

final class WireApplication: UIApplication {

    var callStatusWindowPresenter: CallStatusWindowPresenter!

    private let presenter = DeveloperToolsPresenter()

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {

        callStatusWindowPresenter = callStatusWindowPresenter ?? .init(mainWindow: AppDelegate.shared.mainWindow!)

        if !callStatusWindowPresenter.isVisible {
            callStatusWindowPresenter.show()
        } else {
            callStatusWindowPresenter.hide()
        }


        return;


        guard Bundle.developerModeEnabled else {
            return
        }

        guard motion == .motionShake else { return }

        presenter.presentIfNotDisplayed(with: AppDelegate.shared.appRootRouter, from: self.topmostViewController(onlyFullScreen: false))
    }
}

extension WireApplication: NotificationSettingsRegistrable {

    var shouldRegisterUserNotificationSettings: Bool {
        return !(AutomationHelper.sharedHelper.skipFirstLoginAlerts || AutomationHelper.sharedHelper.disablePushNotificationAlert)
    }
}


final class CallStatusWindowPresenter {

    private var cancellables = Set<AnyCancellable>()

    let mainWindow: UIWindow

    private var statusWindow: UIWindow?

    var isVisible: Bool { statusWindow?.isVisible ?? false }

    init(mainWindow: UIWindow) {
        self.mainWindow = mainWindow


        mainWindow.windowScene!.statusBarManager?.publisher(for: \.isStatusBarHidden).sink { isStatusBarHidden in
            //print("isStatusBarHidden", isStatusBarHidden)
        }.store(in: &cancellables)
    }

    func show() {
        guard !isVisible else { return }

        let labelViewController = LabelViewController(text: "Connecting")
        statusWindow = .init(windowScene: mainWindow.windowScene!)
        statusWindow?.rootViewController = labelViewController
        statusWindow?.windowLevel = mainWindow.windowLevel + 1
        statusWindow?.frame = .init(
            origin: .zero,
            size: .init(
                width: mainWindow.windowScene!.statusBarManager!.statusBarFrame.width,
                height: .zero
            )
        )

        statusWindow?.isHidden = false

        mainWindow.setNeedsUpdateConstraints()
        mainWindow.setNeedsLayout()

        UIView.animate(withDuration: 0.5) { [self] in
            statusWindow?.frame.size.height = mainWindow.windowScene!.statusBarManager!.statusBarFrame.height + 30
            mainWindow.frame.origin.y += statusWindow!.frame.height - mainWindow.windowScene!.statusBarManager!.statusBarFrame.height
            mainWindow.frame.size.height = mainWindow.windowScene!.screen.bounds.height - statusWindow!.frame.height + mainWindow.windowScene!.statusBarManager!.statusBarFrame.height
            mainWindow.layoutIfNeeded()
            mainWindow.updateConstraintsIfNeeded()
        } completion: { isCompleted in
            labelViewController.isLabelHidden = false
        }
    }

    func hide() {
        guard isVisible else { return }

        mainWindow.setNeedsUpdateConstraints()
        mainWindow.setNeedsLayout()

        let labelViewController = statusWindow!.rootViewController as! LabelViewController
        labelViewController.isLabelHidden = true

        UIView.animate(withDuration: 0.5) { [self] in
            statusWindow!.frame.size.height = 0
            mainWindow.frame = mainWindow.windowScene!.screen.bounds
            mainWindow.layoutIfNeeded()
            mainWindow.updateConstraintsIfNeeded()
        } completion: { [self] isCompleted in
            statusWindow?.isHidden = true
            statusWindow = nil
        }
    }

    final class LabelViewController: UIViewController {

        var text: String {
            get { label.text ?? "" }
            set { label.text = newValue }
        }

        var isLabelHidden: Bool {
            get { label.isHidden }
            set { label.isHidden = newValue }
        }

        private let label = UILabel()

        override var shouldAutorotate: Bool { false }
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            [.portrait]
        }

        init(text: String) {
            label.text = text
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .green

            label.isHidden = true
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                label.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
                label.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.topAnchor, multiplier: 1),
                view.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: label.trailingAnchor, multiplier: 1),
                view.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: label.bottomAnchor, multiplier: 1)
            ])
        }
    }
}
