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
    private var statusView: UIView?

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
                // TODO: set label text
                print(callStatus)

            } else {
                // TODO: clear label
                if statusView != nil {
                    await hideStatusView()
                }
            }

        }.value
    }

    @MainActor
    private func showStatusView() async {
        guard
            let mainWindow,
            let rootView = mainWindow.rootViewController?.view,
            let rootSuperview = rootView.superview
        else { return assertionFailure() }

        let statusView = UIView()
        self.statusView = statusView
        rootSuperview.insertSubview(statusView, aboveSubview: rootView)

        statusView.backgroundColor = .green
        //statusView.frame = mainWindow.screen.bounds
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



private final class Setup: UIView {

    private var mainWindow: UIWindow!

    override func didMoveToWindow() {
        DispatchQueue.main.async { [self] in
            setupWindow(setupRootViewController())
        }
    }

    private func setupRootViewController() -> UIViewController {

        let rootViewController = UIViewController()
        rootViewController.title = "Conversation List"
        rootViewController.view.backgroundColor = .white

        let button = UIButton(type: .system)
        button.setTitle("Toggle Call Status", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        rootViewController.view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: rootViewController.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: rootViewController.view.centerYAnchor)
        ])

        let navigationController = UINavigationController(rootViewController: rootViewController)
        var presenter: CallStatusPresenter!
        var isVisible = false

        button.addAction(
            .init { _ in
                let mainWindow = navigationController.view.window!
                presenter = presenter ?? CallStatusPresenter(mainWindow: mainWindow)
                Task { @MainActor in
                    isVisible.toggle()
                    await presenter.updateCallStatus(isVisible ? "Connecting ..." : nil)
                }
            },
            for: .primaryActionTriggered
        )

        return navigationController
    }

    private func setupWindow(_ rootViewController: UIViewController) {
        mainWindow = UIWindow(windowScene: window!.windowScene!)
        mainWindow.rootViewController = rootViewController
        mainWindow.makeKeyAndVisible()
    }
}

/*
#Preview {
    {
        let setupWindow: () -> Void = {
            print("ok")
        }
        let rootView =
        let hostingController = UIHostingController(rootView: )


        var toggleCallStatus: (() -> Void)?
        let rootView = NavigationStack {
            Button("Toggle Call Status") { toggleCallStatus?() }
                .navigationTitle("Lorem Ipsum")
                .toolbarBackground(.visible, for: .navigationBar)
        }
        let hostingController = UIHostingController(rootView: rootView)

        toggleCallStatus = {
            let mainWindow = hostingController.view.window!
//            let presenter = CallStatusPresenter(mainWindow: mainWindow)
//            Task { @MainActor in
//                await presenter.updateCallStatus("Connecting ...")
//            }

            let vc = UIViewController()
            vc.view.backgroundColor = .red
            let window = UIWindow(windowScene: mainWindow.windowScene!)
            window.windowLevel = mainWindow.windowLevel + 1
            window.rootViewController = vc
            window.makeKeyAndVisible()
            objc_setAssociatedObject(mainWindow, &key, window, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        return hostingController



    }()
}

*/
