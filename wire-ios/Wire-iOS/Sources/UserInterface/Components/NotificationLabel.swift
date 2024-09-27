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

class NotificationLabel: RoundedBlurView {
    // MARK: Lifecycle

    // MARK: - View Life Cycle

    init(shouldAnimate: Bool = true) {
        self.shouldAnimate = shouldAnimate
        super.init()
    }

    // MARK: Internal

    private(set) var timer: Timer?

    // MARK: - Setup

    override func setupViews() {
        super.setupViews()

        setCornerRadius(12)
        isHidden = true

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        for item in [blurView, messageLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
            item.clipsToBounds = true
            addSubview(item)
        }
    }

    override func createConstraints() {
        super.createConstraints()

        NSLayoutConstraint.activate([
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    // MARK: - Public Interface

    /// Shows a message with an optional timer.
    /// - Parameters:
    ///   - message: message to show
    ///   - timeInterval: optional time interval after which the message will be hidden
    func show(message: String, hideAfter timeInterval: TimeInterval? = nil) {
        messageLabel.text = message
        animateMessage(show: true) { [weak self] in
            self?.startTimer(with: timeInterval)
        }
    }

    /// Hides message and invalidates the timer.
    func hideAndStopTimer() {
        timer?.invalidate()
        animateMessage(show: false)
    }

    /// Changes visibility of the message label.
    /// No effect if the message has already been hidden after the timer was invalidated.
    /// - Parameter hidden: wether or not the message should be hidden
    func setMessageHidden(_ hidden: Bool) {
        // only change visibility if timer isn't invalid
        guard timer == nil || timer?.isValid == true else {
            return
        }

        animateMessage(show: !hidden)
    }

    // MARK: Private

    private let messageLabel = UILabel(
        key: nil,
        size: .medium,
        weight: .semibold,
        color: .white
    )

    /// use to disable animations for unit tests
    private var shouldAnimate: Bool

    // MARK: - Helpers

    private func animateMessage(show: Bool, completion: (() -> Void)? = nil) {
        if show { isHidden = false }

        let animationBlock: () -> Void = { [weak self] in
            self?.alpha = show ? 1 : 0
        }

        let completionBlock: (Bool) -> Void = { [weak self] _ in
            self?.isHidden = !show
            completion?()
        }

        if shouldAnimate {
            UIView.animate(withDuration: 0.5, animations: animationBlock, completion: completionBlock)
        } else {
            animationBlock()
            completionBlock(true)
        }
    }

    private func startTimer(with timeInterval: TimeInterval?) {
        guard let timeInterval else { return }

        timer = .scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.animateMessage(show: false)
        }
    }
}
