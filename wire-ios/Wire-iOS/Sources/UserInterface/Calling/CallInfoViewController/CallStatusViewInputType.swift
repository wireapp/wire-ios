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

// MARK: - CallStatusViewInputType

protocol CallStatusViewInputType: CallTypeProvider, CBRSettingProvider {
    var state: CallStatusViewState { get }
    var isConstantBitRate: Bool { get }
    var title: String { get }
    var classification: SecurityClassification? { get }
}

// MARK: - CallTypeProvider

protocol CallTypeProvider {
    var isVideoCall: Bool { get }
}

// MARK: - CBRSettingProvider

protocol CBRSettingProvider {
    var userEnabledCBR: Bool { get }
    var isForcedCBR: Bool { get }
}

extension CallStatusViewInputType {
    var callingConfig: CallingConfiguration { .config }

    var overlayBackgroundColor: UIColor {
        switch (isVideoCall, state, callingConfig.isAudioCallColorSchemable) {
        case (true, .ringingIncoming, _),
             (true, .ringingOutgoing, _):
            UIColor.black.withAlphaComponent(0.4)
        case (false, _, false),
             (true, _, _):
            UIColor.black.withAlphaComponent(0.64)
        case (false, _, true):
            UIColor.black.withAlphaComponent(0.64)
        }
    }

    var shouldShowBitrateLabel: Bool {
        isForcedCBR ? isConstantBitRate : userEnabledCBR
    }
}
