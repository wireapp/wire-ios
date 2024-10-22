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

<<<<<<<< HEAD:WireAPI/Sources/WireAPI/APIs/FeatureConfigsAPI/FeatureConfigsAPIV2.swift
import Foundation

class FeatureConfigsAPIV2: FeatureConfigsAPIV1 {

    override var apiVersion: APIVersion {
        .v2
========
extension ProcessInfo {

    var isRunningTests: Bool {
        return environment["XCTestConfigurationFilePath"] != nil
>>>>>>>> aba5b2dca4 (feat: analytics milestone 1 - WPB-8911 (#1825)):wire-ios-sync-engine/Source/ProcessInfo+Tests.swift
    }

}
