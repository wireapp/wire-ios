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
import Cartography
import UIKit
import WireDataModel
import WireSyncEngine
import avs
import DifferenceKit

final class VideoGridViewController: SpinnerCapableViewController {
    // MARK: - Statics

    static let isCoveredKey = "isCovered"

    // MARK: - Private Properties

    private var videoStreams: [VideoStream] {
        if let videoStream = configuration.videoStreams.first(where: { isMaximized(stream: $0.stream) }) {
            return [videoStream]
        }
        return configuration.videoStreams
    }

    private var dataSource: [VideoStream] = []
    private var maximizedView: BaseVideoPreviewView?
    private let gridView = GridView()
    private let thumbnailViewController = PinnableThumbnailViewController()
    private let networkConditionView = NetworkConditionIndicatorView()
    private let hintView = VideoGridHintNotificationLabel()
    private let topStack = UIStackView(axis: .vertical)
    private let mediaManager: AVSMediaManagerInterface
    private var viewCache = [AVSClient: OrientableView]()

    // MARK: - Public Properties

    var configuration: VideoGridConfiguration {
        didSet {
            guard !configuration.isEqual(toConfiguration: oldValue) else { return }
            dismissMaximizedViewIfNeeded(oldPresentationMode: oldValue.presentationMode)
            updateState()
        }
    }

    var previewOverlay: UIView? {
        return thumbnailViewController.contentView
    }

    /// Update view visibility when this view controller is covered or not
    var isCovered: Bool = true {
        didSet {
            guard isCovered != oldValue else { return }
            notifyVisibilityChanged()
            displayIndicatorViewsIfNeeded()
            animateNetworkConditionView()
            hintView.setMessageHidden(isCovered)
        }
    }

    var dismissSpinner: SpinnerCompletion?

    // MARK: - Initialization

    init(configuration: VideoGridConfiguration,
         mediaManager: AVSMediaManagerInterface = AVSMediaManager.sharedInstance()) {

        self.configuration = configuration
        self.mediaManager = mediaManager

        super.init(nibName: nil, bundle: nil)

        setupViews()
        createConstraints()
        updateState()
        displayIndicatorViewsIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateHint(for: .viewDidLoad)
    }

    // MARK: - Setup

    private func setupViews() {
        gridView.dataSource = self
        view.addSubview(gridView)

        addToSelf(thumbnailViewController)

        view.addSubview(topStack)
        topStack.alignment = .center
        topStack.spacing = 10
        topStack.addArrangedSubview(networkConditionView)
        topStack.addArrangedSubview(hintView)

        networkConditionView.accessibilityIdentifier = "network-conditions-indicator"
    }

    private func createConstraints() {
        [gridView, thumbnailViewController.view, topStack, hintView, networkConditionView].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        [gridView, thumbnailViewController.view].forEach {
            $0?.fitInSuperview()
        }

        NSLayoutConstraint.activate([
            topStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topStack.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 24),
            topStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            topStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Public Interface

    public func handleDoubleTap(gesture: UIGestureRecognizer) {
        let location = gesture.location(in: gridView)
        toggleMaximized(view: streamView(at: location))
    }

    // MARK: - View maximization

    private func toggleMaximized(view: BaseVideoPreviewView?) {
        guard let view = view else { return }
        guard allowMaximizationToggling(for: view.stream) else { return }

        let shouldMaximize = !isMaximized(stream: view.stream)

        maximizedView = shouldMaximize ? view : nil
        view.isMaximized = shouldMaximize
        updateVideoGrid(with: videoStreams)
        updateHint(for: .maximizationChanged(maximized: shouldMaximize))
    }

    private func allowMaximizationToggling(for stream: Stream) -> Bool {
        return !(configuration.callHasTwoParticipants && stream.videoState == .screenSharing)
    }

    private func isMaximized(stream: Stream?) -> Bool {
        guard
            let streamId = stream?.streamId,
            let maximizedStreamId = maximizedView?.stream.streamId
        else { return false }

        return streamId == maximizedStreamId
    }

    private func dismissMaximizedViewIfNeeded(oldPresentationMode: VideoGridPresentationMode) {
        guard oldPresentationMode != configuration.presentationMode else { return }
        maximizedView?.isMaximized = false
        maximizedView = nil
    }

    // MARK: - Hint

    private func updateHint(for event: VideoGridEvent) {
        switch event {
        case .viewDidLoad:
            hintView.show(hint: .fullscreen)
        case .configurationChanged:
            guard
                configuration.callHasTwoParticipants,
                let stream = configuration.videoStreams.first?.stream
            else { return }

            if stream.videoState == .some(.screenSharing) {
                hintView.show(hint: .zoom)
            } else if isMaximized(stream: stream) {
                hintView.show(hint: .goBackOrZoom)
            }
        case .maximizationChanged(maximized: let maximized):
            if maximized {
                hintView.show(hint: .goBackOrZoom)
            } else {
                hintView.hideAndStopTimer()
            }
        }
    }

    // MARK: - UI Update

    private func displayIndicatorViewsIfNeeded() {
        networkConditionView.networkQuality = configuration.networkQuality
        networkConditionView.isHidden = shouldHideNetworkCondition
    }

    private var shouldHideNetworkCondition: Bool {
        return isCovered || configuration.networkQuality.isNormal
    }

    private func notifyVisibilityChanged() {
        NotificationCenter.default.post(
            name: .videoGridVisibilityChanged,
            object: nil,
            userInfo: [VideoGridViewController.isCoveredKey: isCovered]
        )
    }

    private func animateNetworkConditionView() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: { self.networkConditionView.alpha = self.isCovered ? 0.0 : 1.0 }
        )
    }

    // MARK: - Grid Update

    private func updateState() {
        Log.calling.debug("\nUpdating video configuration from:\n\(videoConfigurationDescription())")

        displaySpinnerIfNeeded()
        updateSelfPreview()
        updateFloatingVideo(with: configuration.floatingVideoStream)
        updateVideoGrid(with: videoStreams)
        displayIndicatorViewsIfNeeded()
        updateGridViewAxis()
        updateHint(for: .configurationChanged)

        Log.calling.debug("\nUpdated video configuration to:\n\(videoConfigurationDescription())")
    }

    private func displaySpinnerIfNeeded() {
        guard
            configuration.presentationMode == .activeSpeakers,
            configuration.videoStreams.isEmpty
        else {
            dismissSpinner?()
            return
        }

        showLoadingView(title: L10n.Localizable.Call.Grid.noActiveSpeakers)
    }

    private func updateSelfPreview() {
        guard let selfStreamId = ZMUser.selfUser()?.selfStreamId else { return }

        // No stream to show. Update the capture state.
        guard let selfStream = stream(with: selfStreamId) else {
            Log.calling.debug("updating capture state to \(configuration.videoState)")
            selfPreviewView?.updateCaptureState(with: configuration.videoState)
            return
        }

        if let view = selfPreviewView {
            view.stream = selfStream
            view.shouldShowActiveSpeakerFrame = configuration.shouldShowActiveSpeakerFrame
        } else {
            viewCache[selfStreamId] = SelfVideoPreviewView(
                stream: selfStream,
                isCovered: isCovered,
                shouldShowActiveSpeakerFrame: configuration.shouldShowActiveSpeakerFrame
            )
        }
    }

    private func updateFloatingVideo(with state: VideoStream?) {
        // No stream, remove floating video if there is any.
        guard let state = state else {
            Log.calling.debug("Removing self video from floating preview")
            return thumbnailViewController.removeCurrentThumbnailContentView()
        }

        // We only support the self preview in the floating overlay.
        guard state.stream.streamId == ZMUser.selfUser()?.selfStreamId else {
            return Log.calling.error("Invalid operation: Non self preview in overlay")
        }

        // We have a stream but don't have a preview view yet.
        if nil == thumbnailViewController.contentView, let previewView = selfPreviewView {
            Log.calling.debug("Adding self video to floating preview")
            thumbnailViewController.setThumbnailContentView(previewView, contentSize: .previewSize(for: traitCollection))
        }
    }

    private func updateVideoGrid(with newVideoStreams: [VideoStream]) {
        let changeSet = StagedChangeset(source: dataSource, target: newVideoStreams)

        UIView.performWithoutAnimation {
            gridView.reload(using: changeSet) { dataSource = $0 }
        }

        updateStates(with: dataSource)
        pruneCache()
    }

    private func updateStates(with videoStreams: [VideoStream]) {
        videoStreams.forEach {
            let view = (streamView(for: $0.stream) as? VideoPreviewView)

            view?.stream = $0.stream
            view?.shouldShowActiveSpeakerFrame = configuration.shouldShowActiveSpeakerFrame
            view?.isPaused = $0.isPaused
            view?.pinchToZoomRule = PinchToZoomRule(isOneToOneCall: configuration.callHasTwoParticipants)
        }
    }

    private func pruneCache() {
        let existingStreamsIds = Set(viewCache.keys)
        let currentStreamsIds = configuration.allStreamIds

        for deletedStreamId in existingStreamsIds.subtracting(currentStreamsIds) {
            guard deletedStreamId != ZMUser.selfUser()?.selfStreamId else { return }
            viewCache[deletedStreamId]?.removeFromSuperview()
            viewCache.removeValue(forKey: deletedStreamId)
        }
    }

    // MARK: - Grid View Axis

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        thumbnailViewController.updateThumbnailContentSize(.previewSize(for: traitCollection), animated: false)
        updateGridViewAxis()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [updateGridViewAxis] _ in updateGridViewAxis() })
    }

    private func updateGridViewAxis() {
        let newAxis = gridAxis(for: traitCollection)
        guard newAxis != gridView.layoutDirection else { return }
        gridView.layoutDirection = newAxis
    }

    private func gridAxis(for traitCollection: UITraitCollection) -> UICollectionView.ScrollDirection {
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        switch (traitCollection.userInterfaceIdiom, traitCollection.horizontalSizeClass, isLandscape) {
        case (.pad, .regular, true):
            return .horizontal
        default:
            return .vertical
        }
    }

    // MARK: - Helpers

    private func streamView(for stream: Stream) -> UIView? {
        return viewCache[stream.streamId]
    }

    private func streamView(at location: CGPoint) -> BaseVideoPreviewView? {
        guard let indexPath = gridView.indexPathForItem(at: location) else {
            return nil
        }
        return streamView(for: dataSource[indexPath.row].stream) as? BaseVideoPreviewView
    }

    private func stream(with streamId: AVSClient) -> Stream? {
        var stream = configuration.videoStreams.first(where: { $0.stream.streamId == streamId })?.stream

        if stream == nil && configuration.floatingVideoStream?.stream.streamId == streamId {
            stream = configuration.floatingVideoStream?.stream
        }

        return stream
    }

    private var selfPreviewView: SelfVideoPreviewView? {
        guard let selfStreamId = ZMUser.selfUser()?.selfStreamId else {
            return nil
        }
        return viewCache[selfStreamId] as? SelfVideoPreviewView
    }

    private func videoConfigurationDescription() -> String {
        return """
        showing self preview: \(selfPreviewView != nil)
        videos in grid: [\(dataSource)]\n
        """
    }

}

// MARK: - UICollectionViewDataSource

extension VideoGridViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseIdentifier, for: indexPath) as? GridCell else {
            return UICollectionViewCell()
        }

        let videoStream = dataSource[indexPath.row]
        cell.add(streamView: streamView(for: videoStream))

        return cell
    }

    private func streamView(for videoStream: VideoStream) -> OrientableView {
        let streamId = videoStream.stream.streamId

        if let streamView = viewCache[streamId] {
            return streamView
        } else {
            let view = VideoPreviewView(
                stream: videoStream.stream,
                isCovered: isCovered,
                shouldShowActiveSpeakerFrame: configuration.shouldShowActiveSpeakerFrame,
                pinchToZoomRule: PinchToZoomRule(isOneToOneCall: configuration.callHasTwoParticipants)
            )
            viewCache[streamId] = view
            return view
        }
    }
}

// MARK: - Test Helpers

extension VideoGridViewController {
    /// used by snapshot tests
    func hideHintView() {
        hintView.hideAndStopTimer()
    }
}

// MARK: - Extensions

extension ZMEditableUser {
    var selfStreamId: AVSClient {

        guard
            let selfUser = ZMUser.selfUser(),
            let userId = selfUser.remoteIdentifier,
            let clientId = selfUser.selfClient()?.remoteIdentifier
        else {
            fatal("Could not create self user stream which should always exist")
        }

        return AVSClient(userId: userId, clientId: clientId)
    }
}

extension CGSize {

    static let floatingPreviewSmall = CGSize(width: 108, height: 144)
    static let floatingPreviewLarge = CGSize(width: 150, height: 200)

    static func previewSize(for traitCollection: UITraitCollection) -> CGSize {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            return .floatingPreviewLarge
        case .compact, .unspecified:
            return .floatingPreviewSmall
        @unknown default:
            return .floatingPreviewSmall
        }
    }

}

extension Notification.Name {

    static let videoGridVisibilityChanged = Notification.Name(rawValue: "VideoGridVisibilityChanged")

}
