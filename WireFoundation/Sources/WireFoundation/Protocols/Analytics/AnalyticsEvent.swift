//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAccountImageUI

public struct AccountUIModel: Identifiable {

    public let id = UUID()

<<<<<<<< HEAD:WireFoundation/Sources/WireFoundation/Protocols/Analytics/AnalyticsEvent.swift
    public let name: String

    /// Additional metadata.

    public let segmentation: Set<Segmentation>

    /// Create a new `AnalyticsEvent`.
    ///
    /// - Parameters:
    ///   - name: A unique name.
    ///   - segmentation: Additional metadata.

    public init<Collection>(
========
    let avatarSource: AccountImageSource
    let name: String
    let handle: String
    let teamName: String?
    let backendName: String?
    let action: () -> Void

    public init(
        avatarSource: AccountImageSource,
>>>>>>>> e51ed70bed90c4d1b450f7b84370614c7f0fc57b:WireUI/Sources/WireMultiBackendUI/AccountUIModel.swift
        name: String,
        handle: String,
        teamName: String?,
        backendName: String?,
        action: @escaping () -> Void
    ) {
        self.avatarSource = avatarSource
        self.name = name
        self.handle = handle
        self.teamName = teamName
        self.backendName = backendName
        self.action = action
    }

}
