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

final class SendingProgressViewController: UIViewController {

    typealias ProgressMode = SendingProgressViewModel.ProgressMode

    var cancelHandler: (() -> Void)?

    private var circularShadow = CircularProgressView()
    private var circularProgress = CircularProgressView()
    private var connectionStatusLabel = UILabel()

    private let networkStatusObservable: any NetworkStatusObservable
    private var viewModel: SendingProgressViewModel

    var progress: Float = 0 {
        didSet {
            mode = .sending
            viewModel.perform(.updateProgress(progress))
            render(viewModel.displayState, animated: true)
        }
    }

    var mode: ProgressMode = .preparing {
        didSet {
            viewModel.perform(.updateMode(mode))
            render(viewModel.displayState, animated: false)
        }
    }

    func updateProgressMode() {
        render(viewModel.displayState, animated: false)
    }

    init(
        networkStatusObservable: any NetworkStatusObservable,
        viewModel: SendingProgressViewModel = SendingProgressViewModel()
    ) {
        self.networkStatusObservable = networkStatusObservable
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(onCancelTapped)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                SendingProgressViewController
                    .networkStatusDidChange(_:)
            ),
            name: Notification.Name.NetworkStatus,
            object: nil
        )

        circularShadow.lineWidth = 2
        circularShadow.setProgress(1, animated: false)
        circularShadow.alpha = 0.2

        circularProgress.lineWidth = 2
        circularProgress.setProgress(0, animated: false)

        connectionStatusLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        connectionStatusLabel.textAlignment = .center

        view.addSubview(circularShadow)
        view.addSubview(circularProgress)
        view.addSubview(connectionStatusLabel)

        createConstraints()

        updateProgressMode()

        setReachability(from: networkStatusObservable.reachability)
    }

    private func createConstraints() {
        [
            circularShadow,
            circularProgress,
            connectionStatusLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            circularShadow.widthAnchor.constraint(equalToConstant: 48),
            circularShadow.heightAnchor.constraint(equalToConstant: 48),
            circularShadow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularShadow.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            circularProgress.widthAnchor.constraint(equalToConstant: 48),
            circularProgress.heightAnchor.constraint(equalToConstant: 48),
            circularProgress.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularProgress.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            connectionStatusLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
            connectionStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc
    private func onCancelTapped() {
        let effects = viewModel.perform(.cancelTapped)
        perform(effects)
    }

    @objc
    private func networkStatusDidChange(_ notification: Notification) {
        if let status = notification.object as? NetworkStatus {
            setReachability(from: status.reachability)
        }
    }

    func setReachability(from reachability: ServerReachability) {
        viewModel.perform(.updateReachability(reachability))
        render(viewModel.displayState, animated: false)
    }

    private func render(_ displayState: SendingProgressViewModel.DisplayState, animated: Bool) {
        title = displayState.title
        circularProgress.deterministic = displayState.isProgressDeterministic
        circularProgress.setProgress(displayState.progress, animated: animated)
        connectionStatusLabel.isHidden = displayState.isConnectionStatusHidden
        connectionStatusLabel.text = displayState.connectionStatusText
    }

    private func perform(_ effects: [SendingProgressViewModel.Effect]) {
        effects.forEach { effect in
            switch effect {
            case .cancel:
                cancelHandler?()
            }
        }
    }

}
