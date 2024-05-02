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

import avs
@testable import Wire
import XCTest

final class AudioEffectsPickerViewControllerTests: BaseSnapshotTestCase {
    var sut: AudioEffectsPickerViewController! = .none

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        let path = Bundle(for: type(of: self)).path(forResource: "audio_sample", ofType: "m4a")!

        let effects: [AVSAudioEffectType] = [
            .none,
            .pitchupInsane,
            .pitchdownInsane,
            .paceupMed,
            .reverbMax,
            .chorusMax,
            .vocoderMed,
            .pitchUpDownMax
        ]

        self.sut = AudioEffectsPickerViewController(
            recordingPath: path,
            duration: TimeInterval(10.0),
            effects: effects
        )

        self.sut.normalizedLoudness = (0...100).map { Float($0) / 100.0 }
        self.sut.progressView.samples = self.sut.normalizedLoudness
    }

    func prepareForSnapshot() -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()

        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = SemanticColors.View.backgroundDefault
        container.translatesAutoresizingMaskIntoConstraints = false
        sut.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 216),
            container.widthAnchor.constraint(equalToConstant: 320),
            sut.view.topAnchor.constraint(equalTo: container.topAnchor),
            sut.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sut.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sut.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }

    func testInitialState() {
        verify(matching: prepareForSnapshot())
    }

    func testPlayingProgressState() {
        let preparedView = self.prepareForSnapshot()

        self.sut.setState(.playing, animated: false)
        verify(matching: preparedView)
    }

    func testTooltipState() {
        let preparedView = self.prepareForSnapshot()
        self.sut.setState(.tip, animated: false)
        verify(matching: preparedView)
    }

    func testEffectSelectedState() {
        let preparedView = self.prepareForSnapshot()

        sut.selectedAudioEffect = AVSAudioEffectType.chorusMax
        verify(matching: preparedView)
    }
}
