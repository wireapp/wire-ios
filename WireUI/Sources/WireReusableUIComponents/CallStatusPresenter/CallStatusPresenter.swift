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
        print("showStatusView")

        let statusView = UIView()
        self.statusView = statusView
        rootSuperview.insertSubview(statusView, aboveSubview: rootView)
        print(rootSuperview)

        statusView.backgroundColor = .green
        statusView.frame = mainWindow.screen.bounds
        rootView.frame.origin.y += 100
        rootView.frame.size.height -= 100
        rootView.alpha = 0.5
        print(rootView)
    }

    @MainActor
    private func hideStatusView() async {
        //
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        var toggleCallStatus: (() -> Void)?
        let rootView = NavigationStack {
            Button("Toggle Call Status") {
                toggleCallStatus?()
            }
            .navigationTitle("Lorem Ipsum")
            .toolbarBackground(.visible, for: .navigationBar)
        }
        let hostingController = UIHostingController(rootView: rootView)

        toggleCallStatus = {
            let mainWindow = hostingController.view.window!
            let presenter = CallStatusPresenter(mainWindow: mainWindow)
            Task { @MainActor in
                await presenter.updateCallStatus("Connecting ...")
            }
        }

        return hostingController
    }()
}
