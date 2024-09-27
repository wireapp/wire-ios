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
import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

final class AudioEffectsPickerViewControllerTests: XCTestCase {
    // MARK: Internal

    var sut: AudioEffectsPickerViewController! = .none

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        let path = Bundle(for: type(of: self)).path(forResource: "audio_sample", ofType: "m4a")!
        sut = AudioEffectsPickerViewController(recordingPath: path, duration: TimeInterval(10.0))
        sut.normalizedLoudness = (0 ... 100).map { Float($0) / 100.0 }
        sut.progressView.samples = sut.normalizedLoudness
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func prepareForSnapshot() -> UIView {
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()

        let container = UIView()
        container.addSubview(sut.view)
        container.backgroundColor = SemanticColors.View.backgroundDefault
        container.translatesAutoresizingMaskIntoConstraints = false
        sut.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 216),
            container.widthAnchor.constraint(equalToConstant: 320),
            sut.view.topAnchor.constraint(equalTo: container.topAnchor),
            sut.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sut.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sut.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }

    func testInitialState() {
        snapshotHelper.verify(matching: prepareForSnapshot())
    }

    func testPlayingProgressState() {
        let preparedView = prepareForSnapshot()

        sut.setState(.playing, animated: false)
        snapshotHelper.verify(matching: preparedView)
    }

    func testTooltipState() {
        let preparedView = prepareForSnapshot()
        sut.setState(.tip, animated: false)
        snapshotHelper.verify(matching: preparedView)
    }

    func testEffectSelectedState() {
        let preparedView = prepareForSnapshot()

        sut.selectedAudioEffect = AVSAudioEffectType.chorusMax
        snapshotHelper.verify(matching: preparedView)
    }

    // MARK: Private

    private var snapshotHelper: SnapshotHelper!
}
