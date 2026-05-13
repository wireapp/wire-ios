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
import WireDesign

final class MediaBarViewController: UIViewController {
    private let viewModel = MediaBarViewModel()
    private var mediaPlaybackManager: MediaPlaybackManager?

    private var mediaBarView: MediaBar? {
        view as? MediaBar
    }

    required init(mediaPlaybackManager: MediaPlaybackManager?) {
        super.init(nibName: nil, bundle: nil)

        self.mediaPlaybackManager = mediaPlaybackManager
        self.mediaPlaybackManager?.changeObserver = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = MediaBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mediaBarView?.playPauseButton.addTarget(self, action: #selector(playPause(_:)), for: .touchUpInside)
        mediaBarView?.closeButton.addTarget(self, action: #selector(stop(_:)), for: .touchUpInside)

        updatePlayPauseButton()
    }

    func updatePlayPauseButton() {
        let displayState = viewModel.displayState(isPlaying: isPlaying)

        mediaBarView?.playPauseButton.setIcon(icon(for: displayState.playPauseIcon), size: .tiny, for: .normal)
        mediaBarView?.playPauseButton.accessibilityIdentifier = displayState.playPauseAccessibilityIdentifier
    }

    // MARK: - Actions

    @objc
    private func playPause(_ sender: Any?) {
        perform(viewModel.playPauseAction(isPlaying: isPlaying))
    }

    @objc
    private func stop(_ sender: Any?) {
        perform(viewModel.stopAction())
    }

    private func perform(_ action: MediaBarViewModel.Action) {
        switch action {
        case .stop:
            mediaPlaybackManager?.stop()
        case .play:
            mediaPlaybackManager?.play()
        case .pause:
            mediaPlaybackManager?.pause()
        }
    }

    private var isPlaying: Bool {
        mediaPlaybackManager?.activeMediaPlayer?.state == .playing
    }

    private func icon(for playPauseIcon: MediaBarViewModel.PlayPauseIcon) -> StyleKitIcon {
        switch playPauseIcon {
        case .play:
            .play
        case .pause:
            .pause
        }
    }

}

extension MediaBarViewController: MediaPlaybackManagerChangeObserver {

    func activeMediaPlayerStateDidChange() {
        updatePlayPauseButton()
    }
}
