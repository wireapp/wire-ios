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

import WireDataModel
@testable import WireDomain

class MockFeatureConfigLocalStoreProtocol: FeatureConfigLocalStoreProtocol {

    // MARK: - Life cycle

    // MARK: - fetchFeature

    var fetchFeatureName_Invocations: [Feature.Name] = []
    var fetchFeatureName_MockError: Error?
    var fetchFeatureName_MockMethod: ((Feature.Name) async throws -> Feature)?
    var fetchFeatureName_MockValue: Feature?

    func fetchFeature(name: Feature.Name) async throws -> Feature {
        fetchFeatureName_Invocations.append(name)

        if let error = fetchFeatureName_MockError {
            throw error
        }

        if let mock = fetchFeatureName_MockMethod {
            return try await mock(name)
        } else if let mock = fetchFeatureName_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchFeatureName`")
        }
    }

    // MARK: - storeFeature

    var storeFeatureNeedsNotifyUserFeature_Invocations: [(needsNotifyUser: Bool, feature: Feature)] = []
    var storeFeatureNeedsNotifyUserFeature_MockMethod: ((Bool, Feature) async -> Void)?

    func storeFeature(needsNotifyUser: Bool, feature: Feature) async {
        storeFeatureNeedsNotifyUserFeature_Invocations.append((needsNotifyUser: needsNotifyUser, feature: feature))

        guard let mock = storeFeatureNeedsNotifyUserFeature_MockMethod else {
            fatalError("no mock for `storeFeatureNeedsNotifyUserFeature`")
        }

        await mock(needsNotifyUser, feature)
    }

    // MARK: - featureNeedsNotifyUser

    var featureNeedsNotifyUserFeature_Invocations: [Feature] = []
    var featureNeedsNotifyUserFeature_MockMethod: ((Feature) async -> Bool)?
    var featureNeedsNotifyUserFeature_MockValue: Bool?

    func featureNeedsNotifyUser(feature: Feature) async -> Bool {
        featureNeedsNotifyUserFeature_Invocations.append(feature)

        if let mock = featureNeedsNotifyUserFeature_MockMethod {
            return await mock(feature)
        } else if let mock = featureNeedsNotifyUserFeature_MockValue {
            return mock
        } else {
            fatalError("no mock for `featureNeedsNotifyUserFeature`")
        }
    }

    // MARK: - storeFeature

    var storeFeatureNameIsEnabledConfig_Invocations: [(name: Feature.Name, isEnabled: Bool, config: (any Codable)?)] =
        []
    var storeFeatureNameIsEnabledConfig_MockMethod: ((Feature.Name, Bool, (any Codable)?) async -> Void)?

    func storeFeature(name: Feature.Name, isEnabled: Bool, config: (any Codable)?) async {
        storeFeatureNameIsEnabledConfig_Invocations.append((name: name, isEnabled: isEnabled, config: config))

        guard let mock = storeFeatureNameIsEnabledConfig_MockMethod else {
            fatalError("no mock for `storeFeatureNameIsEnabledConfig`")
        }

        await mock(name, isEnabled, config)
    }

    // MARK: - featureConfig

    var featureConfigFeature_Invocations: [Feature] = []
    var featureConfigFeature_MockMethod: ((Feature) async -> (status: Feature.Status, config: Data?))?

    func featureConfig(feature: Feature) async -> (status: Feature.Status, config: Data?) {
        featureConfigFeature_Invocations.append(feature)

        guard let mock = featureConfigFeature_MockMethod else {
            fatal("no mock for `featureConfigFeature`")
        }

        return await mock(feature)
    }

}
