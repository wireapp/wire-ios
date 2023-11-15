////
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

import Foundation

class MessageDependencyResolver {

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    let context: NSManagedObjectContext

    func waitForDependenciesToResolve(for message: any Message) async {

        let hasDependencies = context.performAndWait {
            message.dependentObjectNeedingUpdateBeforeProcessing != nil
        }

        if !hasDependencies {
            return
        }

        Logging.messageProcessing.debug("Message has dependency, waiting")

        await withCheckedContinuation { continuation in
            Task {
                for await _  in NotificationCenter.default.notifications(named: .requestAvailableNotification) {
                    let hasDependencies = self.context.performAndWait {
                        message.dependentObjectNeedingUpdateBeforeProcessing != nil
                    }

                    if !hasDependencies {
                        Logging.messageProcessing.debug("Message dependency resolved")
                        continuation.resume()
                        break
                    } else {
                        Logging.messageProcessing.debug("Message has dependency, waiting")
                    }
                }
            }
        }
    }
}
