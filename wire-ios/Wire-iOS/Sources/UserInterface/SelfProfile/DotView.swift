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
import WireSyncEngine

final class DotView: UIView {

    private let circleLayer = CALayer()
    private let centerLayer = CALayer()
    private var userObserver: NSObjectProtocol!
    private var clientsObserverTokens: [NSObjectProtocol] = []
    private let user: ZMUser?
    var hasUnreadMessages: Bool = false {
        didSet { self.updateIndicator() }
    }

    var showIndicator: Bool {
        get {
            return !isHidden
        }

        set {
            isHidden = !newValue
        }
    }

    init(user: ZMUser? = nil) {
        self.user = user
        super.init(frame: .zero)
        isHidden = true

        // Configure circle layer
        circleLayer.backgroundColor = UIColor.white.cgColor
        circleLayer.cornerRadius = 0
        circleLayer.masksToBounds = true
        layer.addSublayer(circleLayer)

        // Configure center layer
        centerLayer.backgroundColor = UIColor.accent().cgColor
        centerLayer.cornerRadius = 0
        centerLayer.masksToBounds = true
        layer.addSublayer(centerLayer)

        createConstraints()

        if let userSession = ZMUserSession.shared(), let user {
            userObserver = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }

        createClientObservers()
    }

    private func createConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 30),
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Layout circleLayer and centerLayer
        circleLayer.frame = bounds
        circleLayer.cornerRadius = bounds.width / 2

        let inset: CGFloat = 1
        centerLayer.frame = bounds.insetBy(dx: inset, dy: inset)
        centerLayer.cornerRadius = centerLayer.bounds.width / 2
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createClientObservers() {
        guard let user else { return }
        clientsObserverTokens = user.clients.compactMap {
            UserClientChangeInfo.add(
                observer: self,
                for: $0
            )
        }
    }

    func updateIndicator() {
        if hasUnreadMessages || user?.readReceiptsEnabledChangedRemotely == true {
            showIndicator = true
            return
        }

        if let count = user?.clientsRequiringUserAttention.count, count > 0 {
            showIndicator = true
            return
        }
    }
}

// MARK: - User Observing

extension DotView: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.trustLevelChanged ||
                changeInfo.clientsChanged ||
                changeInfo.accentColorValueChanged ||
                changeInfo.readReceiptsEnabledChanged ||
                changeInfo.readReceiptsEnabledChangedRemotelyChanged else { return }

        updateIndicator()

        if changeInfo.clientsChanged {
            createClientObservers()
        }
    }
}

// MARK: - Clients observer

extension DotView: UserClientObserver {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        guard changeInfo.needsToNotifyUserChanged else { return }
        updateIndicator()
    }
}
