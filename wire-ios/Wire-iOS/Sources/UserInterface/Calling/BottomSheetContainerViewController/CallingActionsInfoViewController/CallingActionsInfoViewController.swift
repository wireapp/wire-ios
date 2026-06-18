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
import WireDataModel
import WireDesign

/// Participants-list container used by `CallingActionsInfoRepresentable`.
/// Renders security level banner, participants header, and scrollable participants list.
/// Call action buttons are owned by `CallPanelView` in both portrait and landscape.
final class CallingActionsInfoViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    private let participantsHeaderHeight: CGFloat = 42
    private let cellHeight: CGFloat = 56
    private let selfUser: UserType

    private var collectionView: CallParticipantsListView!
    private let stackView = UIStackView(axis: .vertical)
    private var participantsHeaderView = UIView()
    private let securityLevelView = SecurityLevelView()
    private var participantsHeaderLabel = DynamicFontLabel(
        fontSpec: .smallSemiboldFont,
        color: SemanticColors.Label.textSectionHeader
    )

    var participants: CallParticipantsList {
        didSet {
            updateRows()
            participantsHeaderLabel.text = L10n.Localizable.Call.Participants.showAll(participants.count).uppercased()
        }
    }

    init(
        participants: CallParticipantsList,
        selfUser: UserType
    ) {
        self.participants = participants
        self.selfUser = selfUser
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRows()
    }

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0

        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0

        participantsHeaderView.backgroundColor = SemanticColors.View.backgroundDefault
        participantsHeaderView.addSubview(participantsHeaderLabel)
        participantsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        participantsHeaderLabel.applyStyle(.headerLabel)
        participantsHeaderLabel.accessibilityTraits.insert(.header)
        participantsHeaderLabel.text = L10n.Localizable.Call.Participants.showAll(participants.count).uppercased()

        let collectionView = CallParticipantsListView(collectionViewLayout: collectionViewLayout, selfUser: selfUser)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.bounces = true
        collectionView.delegate = self
        self.collectionView = collectionView

        [
            securityLevelView,
            participantsHeaderView,
            collectionView
        ].forEach(stackView.addArrangedSubview)

        CallParticipantsListCellConfiguration.prepare(collectionView)
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            participantsHeaderView.heightAnchor.constraint(equalToConstant: participantsHeaderHeight),
            participantsHeaderLabel.leadingAnchor.constraint(
                equalTo: participantsHeaderView.leadingAnchor,
                constant: 16.0
            ),
            participantsHeaderLabel.centerYAnchor.constraint(equalTo: participantsHeaderView.centerYAnchor),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            participantsHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            participantsHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            securityLevelView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    private func updateRows() {
        collectionView?.rows = participants
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - CallInfoConfigurationObserver

extension CallingActionsInfoViewController: CallInfoConfigurationObserver {
    func didUpdateConfiguration(configuration: CallInfoConfiguration) {
        securityLevelView.configure(with: configuration.classification)
    }
}
