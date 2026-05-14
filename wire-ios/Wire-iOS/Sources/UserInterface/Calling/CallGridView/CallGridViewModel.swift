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

import avs
import UIKit
import WireSyncEngine

struct CallGridViewModel {

    struct NetworkConditionViewState {
        let networkQuality: NetworkQuality
        let isHidden: Bool
        let alpha: CGFloat
    }

    enum HintAction {
        case none
        case hide
        case show(CallGridHintKind)
    }

    func displayedStreams(
        configuration: CallGridViewControllerInput,
        maximizedStreamId: AVSClient?
    ) -> [Stream] {
        if let stream = configuration.streams.first(where: { $0.streamId == maximizedStreamId }) {
            return [stream]
        }

        return configuration.streams
    }

    func shouldDisplaySpinner(configuration: CallGridViewControllerInput) -> Bool {
        configuration.presentationMode == .activeSpeakers && configuration.streams.isEmpty
    }

    func shouldShowBorderWhenVideoIsStopped(
        streamCount: Int,
        hasFloatingStream: Bool
    ) -> Bool {
        let gridHasOnlyOneTile = streamCount == 1
        let gridIsOneToOneWithFloatingTile = gridHasOnlyOneTile && hasFloatingStream

        return !gridHasOnlyOneTile && !gridIsOneToOneWithFloatingTile
    }

    func allowsMaximizationToggling(
        for stream: Stream,
        isMaximized: Bool,
        streamCount: Int,
        hasFloatingStream: Bool
    ) -> Bool {
        let gridHasOnlyOneTile = streamCount == 1
        let gridIsOneToOneWithFloatingTile = gridHasOnlyOneTile && hasFloatingStream
        let isStreamScreenSharingOneToOne = gridIsOneToOneWithFloatingTile && stream.isScreenSharing
        let isStreamMinimizedAndNotSharingVideo = !isMaximized && !stream.isSharingVideo

        return !isStreamScreenSharingOneToOne && !(isStreamMinimizedAndNotSharingVideo && gridHasOnlyOneTile)
    }

    func hintAction(
        for event: CallGridEvent,
        configuration: CallGridViewControllerInput,
        maximizedStreamId: AVSClient?
    ) -> HintAction {
        switch event {
        case .viewDidLoad:
            return .none
        case .connectionEstablished:
            return .show(.fullscreen)
        case .configurationChanged where configuration.callHasTwoParticipants:
            guard
                let stream = configuration.streams.first,
                stream.isSharingVideo
            else { return .none }

            if stream.isScreenSharing {
                return .show(.zoom)
            } else if stream.streamId == maximizedStreamId {
                return .show(.goBackOrZoom)
            }

            return .none
        case let .maximizationChanged(stream: stream, maximized: maximized):
            guard maximized else { return .hide }
            return .show(stream.isSharingVideo ? .goBackOrZoom : .goBack)
        default:
            return .none
        }
    }

    func networkConditionViewState(
        isCovered: Bool,
        networkQuality: NetworkQuality
    ) -> NetworkConditionViewState {
        NetworkConditionViewState(
            networkQuality: networkQuality,
            isHidden: isCovered || networkQuality.isNormal,
            alpha: isCovered ? 0.0 : 1.0
        )
    }

    func requestedVideoStreams(
        forPage page: Int,
        maxItemsPerPage: Int,
        dataSource: [Stream],
        visibleClientsSharingVideo: Set<AVSClientVideoStream>
    ) -> [AVSClientVideoStream]? {
        let startIndex = page * maxItemsPerPage
        let endIndex = min(startIndex + maxItemsPerPage, dataSource.count)

        guard dataSource.indices.contains(startIndex),
              endIndex > startIndex
        else { return nil }

        let clientsWithVideo = dataSource[startIndex ..< endIndex]
            .filter(\.isSharingVideo)

        let oneStreamDisplayedExcludingSelf = clientsWithVideo.count == 1
        let clientStreams = clientsWithVideo
            .map { client in
                AVSClientVideoStream(
                    client: client.streamId,
                    quality: oneStreamDisplayedExcludingSelf ? .high : .low
                )
            }

        guard Set(clientStreams) != visibleClientsSharingVideo else { return nil }

        return clientStreams
    }

    func gridAxis(
        userInterfaceIdiom: UIUserInterfaceIdiom,
        horizontalSizeClass: UIUserInterfaceSizeClass,
        isLandscape: Bool?
    ) -> UICollectionView.ScrollDirection {
        switch (userInterfaceIdiom, horizontalSizeClass, isLandscape) {
        case (.pad, .regular, true), (.phone, _, true):
            .horizontal
        default:
            .vertical
        }
    }
}
