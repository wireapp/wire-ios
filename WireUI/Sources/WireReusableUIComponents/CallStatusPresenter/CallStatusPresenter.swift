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
    private var statusView: CallStatusView?

    @MainActor
    public init(mainWindow: UIWindow) {
        self.mainWindow = mainWindow
    }

    deinit {
        guard let mainWindow, let statusView else { return }

        Task { @MainActor in
            statusView.removeFromSuperview()
            if let view = mainWindow.rootViewController?.viewIfLoaded {
                view.frame = mainWindow.bounds
            }
        }
    }

    public func updateCallStatus(_ callStatus: CallStatus?) async {
        print("updateCallStatus", callStatus)
        await Task { @MainActor [self] in

            if let callStatus {
                if statusView == nil {
                    await setupStatusView()
                }
                await updateStatusView(callStatus)

            } else {
                await updateStatusView(callStatus)
                if statusView != nil {
                    await tearDownStatusView()
                }
            }

        }.value
    }

    @MainActor
    private func setupStatusView() async {

        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let rootSuperview = rootView.superview
        else { return assertionFailure() }

        print("setupStatusView")

        let statusView = CallStatusView(frame: .init(origin: .zero, size: .init(width: mainWindow.frame.width, height: 0)))
        rootSuperview.insertSubview(statusView, aboveSubview: rootView)
        self.statusView = statusView
    }

    @MainActor
    private func updateStatusView(_ callStatus: CallStatus?) async {
        guard let statusView else { return }

        await withCheckedContinuation { continuation in

            if let callStatus {
                statusView.callStatus = callStatus
                statusView.frame.size.height = 100

                statusView.setNeedsLayout()
                UIView.animate(withDuration: 3) {
                    statusView.layoutIfNeeded()
                } completion: { _ in
                    continuation.resume()
                }
            } else {
                //
            }
        }
    }

    @MainActor
    private func tearDownStatusView() async {

        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            statusView != nil
        else { return assertionFailure() }

        print("tearDownStatusView")

        await withCheckedContinuation { continuation in
            rootView.frame = mainWindow.screen.bounds
            continuation.resume()
        }

        statusView = nil
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let view = UIView()
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Toggle Call Status", for: .normal)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
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
