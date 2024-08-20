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
        await Task { @MainActor [self] in

            if let callStatus {
                if statusView == nil {
                    await showStatusView()
                }
                statusView?.callStatus = callStatus

            } else {
                statusView?.callStatus = .none
                if statusView != nil {
                    await hideStatusView()
                }
            }

        }.value

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            print("statusViewFrame", self.statusView?.frame)
            print("mainWindow.rootViewController?.view", self.mainWindow?.rootViewController?.view.frame)
        }
    }

    @MainActor
    private func showStatusView() async {
        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let rootSuperview = rootView.superview
        else { return assertionFailure() }

        let statusView = CallStatusView(
            frame: .init(
                origin: .zero,
                size: .init(width: mainWindow.frame.width, height: 0)
            )
        )
        self.statusView = statusView
        rootSuperview.insertSubview(statusView, aboveSubview: rootView)

        rootView.frame.origin.y += 100
        rootView.frame.size.height -= 100
    }

    @MainActor
    private func hideStatusView() async {
        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let statusView
        else { return assertionFailure() }
        print("hide")

        await withCheckedContinuation { continuation in
            rootView.frame = mainWindow.screen.bounds
            continuation.resume()
        }
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
            button.tag += 1
            let callStatus: CallStatus? = if button.tag % 2 == 0 { "Connecting ..." } else { .none }
            setCallStatus(callStatus, view.window!)
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



@available(iOS 17, *)
#Preview("X") {
    SetupView()
}

final class SetupView: UIView {
    override func didMoveToWindow() {

        let view = UIView()
        view.backgroundColor = .red
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        window?.rootViewController?.view.frame.origin.y += 100
    }
}
