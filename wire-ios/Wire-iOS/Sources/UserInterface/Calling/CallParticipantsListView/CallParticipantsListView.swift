//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents

typealias CallParticipantsList = [CallParticipantsListCellConfiguration]

protocol CallParticipantsListCellConfigurable: Reusable {
    func configure(with configuration: CallParticipantsListCellConfiguration,
                   selfUser: UserType)
}

enum CallParticipantsListCellConfiguration: Hashable {

    case callParticipant(
        user: HashBoxUser,
        videoState: VideoState?,
        microphoneState: MicrophoneState?,
        activeSpeakerState: ActiveSpeakerState
    )
    case showAll(totalCount: Int)

    var cellType: CallParticipantsListCellConfigurable.Type {
        switch self {
        case .callParticipant: return UserCell.self
        case .showAll: return ShowAllParticipantsCell.self
        }
    }

    // MARK: - Convenience

    static var allCellTypes: [UICollectionViewCell.Type] {
        return [
            UserCell.self,
            ShowAllParticipantsCell.self
        ]
    }

    static func prepare(_ collectionView: UICollectionView) {
        allCellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.reuseIdentifier)
        }
    }
}

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

extension CallParticipantsListView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellConfiguration = rows[indexPath.row]
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: cellConfiguration.cellType.reuseIdentifier, for: indexPath)

        if let configurableCell = cell as? CallParticipantsListCellConfigurable {
            configurableCell.configure(with: cellConfiguration,
                                       selfUser: selfUser)
        }
        return cell
    }

}

extension UserCell: CallParticipantsListCellConfigurable {

    func configure(with configuration: CallParticipantsListCellConfiguration,
                   selfUser: UserType) {
        guard case let .callParticipant(user, videoState, microphoneState, activeSpeakerState) = configuration else { preconditionFailure() }
        contentBackgroundColor = .clear
        hidesSubtitle = true
        accessoryIconView.isHidden = true
        microphoneIconView.set(style: MicrophoneIconStyle(
            state: microphoneState,
            shouldPulse: activeSpeakerState.isSpeakingNow)
        )
        videoIconView.set(style: VideoIconStyle(state: videoState))
        configure(with: user.value, selfUser: selfUser)
        backgroundColor = SemanticColors.View.backgroundDefaultWhite
    }

}
