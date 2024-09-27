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
import WireCommonComponents
import WireDesign
import WireSyncEngine

typealias CallParticipantsList = [CallParticipantsListCellConfiguration]

// MARK: - CallParticipantsListCellConfigurable

protocol CallParticipantsListCellConfigurable: Reusable {
    func configure(
        with configuration: CallParticipantsListCellConfiguration,
        selfUser: UserType
    )
}

// MARK: - CallParticipantsListCellConfiguration

enum CallParticipantsListCellConfiguration: Hashable {
    case callParticipant(
        user: HashBoxUser,
        callParticipantState: CallParticipantState,
        activeSpeakerState: ActiveSpeakerState
    )
    case showAll(totalCount: Int)

    var cellType: CallParticipantsListCellConfigurable.Type {
        switch self {
        case .callParticipant: UserCell.self
        case .showAll: ShowAllParticipantsCell.self
        }
    }

    // MARK: - Convenience

    static var allCellTypes: [UICollectionViewCell.Type] {
        [
            UserCell.self,
            ShowAllParticipantsCell.self,
        ]
    }

    static func prepare(_ collectionView: UICollectionView) {
        for cellType in allCellTypes {
            collectionView.register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
        }
    }
}

// MARK: - CallParticipantsListView

final class CallParticipantsListView: UICollectionView {
    let selfUser: UserType

    var rows = CallParticipantsList() {
        didSet {
            reloadData()
        }
    }

    init(collectionViewLayout: UICollectionViewLayout, selfUser: UserType) {
        self.selfUser = selfUser
        super.init(frame: .zero, collectionViewLayout: collectionViewLayout)

        self.dataSource = self
        backgroundColor = .clear
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: UICollectionViewDataSource

extension CallParticipantsListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rows.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cellConfiguration = rows[indexPath.row]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellConfiguration.cellType.reuseIdentifier,
            for: indexPath
        )

        if let configurableCell = cell as? CallParticipantsListCellConfigurable {
            configurableCell.configure(
                with: cellConfiguration,
                selfUser: selfUser
            )
        }
        return cell
    }
}

// MARK: - UserCell + CallParticipantsListCellConfigurable

extension UserCell: CallParticipantsListCellConfigurable {
    func configure(
        with configuration: CallParticipantsListCellConfiguration,
        selfUser: UserType
    ) {
        guard case let .callParticipant(hashBoxUser, callParticipantState, activeSpeakerState) = configuration else {
            preconditionFailure()
        }

        let user = hashBoxUser.value
        hidesSubtitle = true
        accessoryIconView.isHidden = true
        switch callParticipantState {
        case let .connected(videoState, microphoneState):
            microphoneIconView.set(style: MicrophoneIconStyle(
                state: microphoneState,
                shouldPulse: activeSpeakerState.isSpeakingNow
            ))
            videoIconView.set(style: VideoIconStyle(state: videoState))
            connectingLabel.isHidden = true
            unconnectedStateOverlay.isHidden = true

        case .connecting, .unconnectedButMayConnect:
            microphoneIconView.set(style: MicrophoneIconStyle(
                state: nil,
                shouldPulse: false
            ))
            videoIconView.set(style: VideoIconStyle(state: nil))
            connectingLabel.isHidden = false
            unconnectedStateOverlay.isHidden = false

        default:
            microphoneIconView.set(style: MicrophoneIconStyle(
                state: nil,
                shouldPulse: activeSpeakerState.isSpeakingNow
            ))
            videoIconView.set(style: VideoIconStyle(state: nil))
            connectingLabel.isHidden = true
            unconnectedStateOverlay.isHidden = true
        }
        configure(
            user: user,
            isSelfUserPartOfATeam: selfUser.hasTeam
        )
        backgroundColor = SemanticColors.View.backgroundDefaultWhite
    }
}
