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

import Foundation

public final class SendableBatchObserver {
    // MARK: Lifecycle

    public init(sendables: [Sendable]) {
        self.sendables = sendables
        self.observerToken = NotificationCenter.default.addObserver(
            forName: contextWasMergedNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.onDeliveryChanged()
            }
        }
    }

    deinit {
        if let observer = self.observerToken {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: Public

    public let sendables: [Sendable]

    public var sentHandler: (() -> Void)?
    public var progressHandler: ((Float) -> Void)?

    public var allSendablesSent: Bool {
        !sendables.contains { !$0.isSent }
    }

    public func onDeliveryChanged() {
        if allSendablesSent {
            DispatchQueue.main.async { [weak self] in
                self?.sentHandler?()
            }
        }

        updateProgress()
    }

    // MARK: Private

    private var observerToken: Any?

    private func updateProgress() {
        var totalProgress: Float = 0

        for message in sendables {
            if message.isSent {
                totalProgress += 1.0 / Float(sendables.count)
            } else {
                let messageProgress = (message.deliveryProgress ?? 0)
                totalProgress += messageProgress / Float(sendables.count)
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.progressHandler?(totalProgress)
        }
    }
}
