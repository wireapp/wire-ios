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
import WireUtilities

// MARK: - CallHapticsGeneratorType

protocol CallHapticsGeneratorType {
    func trigger(event: CallHapticsEvent)
}

// MARK: - CallHapticsEvent

enum CallHapticsEvent: String {
    case start
    case reconnect
    case join
    case leave
    case end
    case toggleVideo

    // MARK: Internal

    enum FeedbackType {
        case success
        case warning
        case impact
    }

    var feedbackType: FeedbackType {
        switch self {
        case .join,
             .reconnect,
             .start: .success
        case .end,
             .leave: .warning
        case .toggleVideo: .impact
        }
    }
}

// MARK: - CallHapticsGenerator

final class CallHapticsGenerator: CallHapticsGeneratorType {
    // MARK: Internal

    func trigger(event: CallHapticsEvent) {
        Log.calling.debug("Triggering haptic feedback event: \(event.rawValue)")
        prepareFeedback(for: event)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.executeFeedback(for: event)
        }
    }

    // MARK: Private

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private func prepareFeedback(for event: CallHapticsEvent) {
        switch event.feedbackType {
        case .success,
             .warning: notificationGenerator.prepare()
        case .impact: impactGenerator.prepare()
        }
    }

    private func executeFeedback(for event: CallHapticsEvent) {
        switch event.feedbackType {
        case .success: notificationGenerator.notificationOccurred(.success)
        case .warning: notificationGenerator.notificationOccurred(.warning)
        case .impact: impactGenerator.impactOccurred()
        }
    }
}
