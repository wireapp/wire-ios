//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import SnapshotTesting
import WireCommonComponents
import XCTest

class BaseSnapshotTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        // Enable when the design of the view has changed in order to update the reference snapshots
        isRecording = strcmp(getenv("RECORDING_SNAPSHOTS"), "YES") == 0

        FontScheme.configure(with: .large)
    }

}
