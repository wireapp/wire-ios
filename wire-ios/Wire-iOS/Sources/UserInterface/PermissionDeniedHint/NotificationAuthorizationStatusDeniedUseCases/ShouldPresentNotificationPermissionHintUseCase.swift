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

import UserNotifications
import WireSystem
import WireUtilities

struct ShouldPresentNotificationPermissionHintUseCase<DateProvider>: ShouldPresentNotificationPermissionHintUseCaseProtocol
where DateProvider: CurrentDateProviding {

    var currentDateProvider: DateProvider
    var userDefaults: UserDefaults
    var userNotificationCenter: UserNotificationCenterAbstraction

    func invoke() async -> Bool {

        // show hint only if `authorizationStatus` is `.denied`
        let notificationSettings = await userNotificationCenter.notificationSettings()
        guard notificationSettings.authorizationStatus == .denied else { return false }

        let lastPresentationDate = userDefaults.value(for: .lastTimeNotificationPermissionHintWasShown)
        if let lastPresentationDate, lastPresentationDate > currentDateProvider.now.addingTimeInterval(-.oneDay) {
            // hint has already been shown within the last 24 hours
            return false
        } else {
            return true
        }
    }
}

// MARK: - ShouldPresentNotificationPermissionHintUseCase + init()

extension ShouldPresentNotificationPermissionHintUseCase where DateProvider == SystemDateProvider {

    init(
        currentDateProvider: SystemDateProvider = .init(),
        userDefaults: UserDefaults = .standard,
        userNotificationCenter: UserNotificationCenterAbstraction = .wrapper(.current())
    ) {
        self.currentDateProvider = currentDateProvider
        self.userDefaults = userDefaults
        self.userNotificationCenter = userNotificationCenter
    }
}
