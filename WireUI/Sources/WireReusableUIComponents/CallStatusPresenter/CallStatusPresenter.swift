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

import SwiftUI

/// For the provided `mainWindow` argument this class resizes the view of the
/// root view controller's view and displays a view with call status information.
public final class CallStatusPresenter: CallStatusPresenting, @unchecked Sendable {

    @MainActor
    private unowned let mainWindow: UIWindow?
    @MainActor
    private var backgroundView: UIView?
    @MainActor
    private var statusLabel: UILabel?

    @MainActor
    public init(mainWindow: UIWindow) {
        self.mainWindow = mainWindow
    }

    deinit {
        guard let mainWindow, let backgroundView else { return }

        Task { @MainActor in
            backgroundView.removeFromSuperview()
            if let view = mainWindow.rootViewController?.viewIfLoaded {
                view.frame = mainWindow.bounds
            }
        }
    }

    public func updateCallStatus(_ callStatus: CallStatus?) async {
        print("updateCallStatus", callStatus)
        await Task { @MainActor [self] in

            if let callStatus {
                if backgroundView == nil {
                    setupBackgroundView()
                }
                await showStatus(callStatus)

            } else {
                await hideStatus()
                if backgroundView != nil {
                    tearDownBackgroundView()
                }
            }

        }.value
    }

    @MainActor
    private func setupBackgroundView() {

        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let rootSuperview = rootView.superview
        else { return assertionFailure() }

        print("setupStatusView")

        let backgroundView = UIView()
        rootSuperview.insertSubview(backgroundView, aboveSubview: rootView)
        backgroundView.frame.size.width = mainWindow.bounds.width
        self.backgroundView = backgroundView

        let statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.textAlignment = .center
        statusLabel.alpha = 0
        backgroundView.addSubview(statusLabel)
        self.statusLabel = statusLabel
    }

    @MainActor
    private func showStatus(_ callStatus: CallStatus) async {
        print(0)
        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let backgroundView,
            let statusLabel
        else { return assertionFailure() }

            print(1)
        if statusLabel.alpha != 0 {
            print(2)
            await UIView.animate(duration: 2) {
                print(2.1)
                statusLabel.alpha = 0
                print(2.2)
            }
            print(2.3)
        }

            print(3)
        statusLabel.text = callStatus
        statusLabel.frame.origin.x = 20
        statusLabel.frame.size.width = backgroundView.bounds.width - 40
        statusLabel.frame.size.height = statusLabel.sizeThatFits(CGSize(
            width: statusLabel.frame.size.width,
            height: .greatestFiniteMagnitude
        )).height
        print("statusLabel.frame", statusLabel.frame)
        print("backgroundView.bounds", backgroundView.bounds)

        await UIView.animate(duration: 2) {
            backgroundView.frame.size.height = statusLabel.frame.size.height
            var f = rootView.frame
            f.origin.y = backgroundView.frame.size.height
            f.size.height = mainWindow.bounds.height - f.origin.y
            rootView.frame = f
//            rootView.frame.origin.y = backgroundView.frame.size.height
//            rootView.frame.size.height = mainWindow.bounds.height - backgroundView.frame.size.height
//            rootView.setNeedsUpdateConstraints()
//            rootView.updateConstraintsIfNeeded()
        }
        print(4)
        await UIView.animate(duration: 2) {
            statusLabel.alpha = 1
        }
        print(5)
    }

    @MainActor
    private func hideStatus() async {
        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let backgroundView,
            let statusLabel
        else { return assertionFailure() }

        if statusLabel.alpha != 0 {
            await UIView.animate(duration: 2) {
                statusLabel.alpha = 0
            }
        }
        await UIView.animate(duration: 2) {
            backgroundView.frame.size.height = 0
            rootView.frame = mainWindow.bounds
        }
    }

    @MainActor
    private func tearDownBackgroundView() {
        print("tearDownBackgroundView")
        backgroundView?.removeFromSuperview()
        backgroundView = nil
    }
}

// MARK: - UIView+animate async

private extension UIView {

    @discardableResult
    class func animate(
        duration: TimeInterval,
        animations: @escaping () -> Void
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            animate(withDuration: 0, animations: animations) { isFinished in
                continuation.resume(returning: isFinished)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let view = UIView()
        view.backgroundColor = .init(white: 0.9, alpha: 1)
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Toggle Call Status", for: .normal)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        button.addAction(.init { _ in
            let callStatus: CallStatus? = if button.tag % 2 == 0 { "Connecting ..." } else { .none }
            setCallStatus(callStatus, view.window!)
            button.tag += 1
        }, for: .primaryActionTriggered)
        return view
    }()
}

@MainActor
private func setCallStatus(_ callStatus: CallStatus?, _ mainWindow: UIWindow) {
    let presenter = mainWindow.rootViewController?.callStatusPresenter ?? CallStatusPresenter(mainWindow: mainWindow)
    mainWindow.rootViewController?.callStatusPresenter = presenter
    Task { await presenter.updateCallStatus(callStatus) }
}

private extension UIViewController {
    var callStatusPresenter: CallStatusPresenter? {
        get { objc_getAssociatedObject(self, &presenterKey) as? CallStatusPresenter }
        set { objc_setAssociatedObject(self, &presenterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
private nonisolated(unsafe) var presenterKey = 0
