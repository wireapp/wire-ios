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

import Combine
import WireAPI
import WireDataModel

@testable import WireDomain

class MockFeatureConfigRepositoryProtocol: FeatureConfigRepositoryProtocol {
    // MARK: - Life cycle
    
    // MARK: - pullFeatureConfigs
    
    var pullFeatureConfigs_Invocations: [Void] = []
    var pullFeatureConfigs_MockError: Error?
    var pullFeatureConfigs_MockMethod: (() async throws -> Void)?
    
    func pullFeatureConfigs() async throws {
        pullFeatureConfigs_Invocations.append(())
        
        if let error = pullFeatureConfigs_MockError {
            throw error
        }
        
        guard let mock = pullFeatureConfigs_MockMethod else {
            fatalError("no mock for `pullFeatureConfigs`")
        }
        
        try await mock()
    }
    
    // MARK: - observeFeatureStates
    
    var observeFeatureStates_Invocations: [Void] = []
    var observeFeatureStates_MockMethod: (() -> AnyPublisher<FeatureState, Never>)?
    var observeFeatureStates_MockValue: AnyPublisher<FeatureState, Never>?
    
    func observeFeatureStates() -> AnyPublisher<FeatureState, Never> {
        observeFeatureStates_Invocations.append(())
        
        if let mock = observeFeatureStates_MockMethod {
            return mock()
        } else if let mock = observeFeatureStates_MockValue {
            return mock
        } else {
            fatalError("no mock for `observeFeatureStates`")
        }
    }
    
    // MARK: - fetchFeatureConfig<T: Decodable>
    
    func fetchFeatureConfig<T: Decodable>(with name: Feature.Name, type: T.Type) async throws -> LocalFeature<T> {
        fatalError("to implement using generics")
    }
    
    // MARK: - updateFeatureConfig
    
    var updateFeatureConfig_Invocations: [FeatureConfig] = []
    var updateFeatureConfig_MockError: Error?
    var updateFeatureConfig_MockMethod: ((FeatureConfig) async throws -> Void)?
    
    func updateFeatureConfig(_ featureConfig: FeatureConfig) async throws {
        updateFeatureConfig_Invocations.append(featureConfig)
        
        if let error = updateFeatureConfig_MockError {
            throw error
        }
        
        guard let mock = updateFeatureConfig_MockMethod else {
            fatalError("no mock for `updateFeatureConfig`")
        }
        
        try await mock(featureConfig)
    }
    
    // MARK: - fetchNeedsToNotifyUser
    
    var fetchNeedsToNotifyUserFor_Invocations: [Feature.Name] = []
    var fetchNeedsToNotifyUserFor_MockError: Error?
    var fetchNeedsToNotifyUserFor_MockMethod: ((Feature.Name) async throws -> Bool)?
    var fetchNeedsToNotifyUserFor_MockValue: Bool?
    
    func fetchNeedsToNotifyUser(for name: Feature.Name) async throws -> Bool {
        fetchNeedsToNotifyUserFor_Invocations.append(name)
        
        if let error = fetchNeedsToNotifyUserFor_MockError {
            throw error
        }
        
        if let mock = fetchNeedsToNotifyUserFor_MockMethod {
            return try await mock(name)
        } else if let mock = fetchNeedsToNotifyUserFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchNeedsToNotifyUserFor`")
        }
    }
    
    // MARK: - storeNeedsToNotifyUser
    
    var storeNeedsToNotifyUserForFeatureName_Invocations: [(notifyUser: Bool, name: Feature.Name)] = []
    var storeNeedsToNotifyUserForFeatureName_MockError: Error?
    var storeNeedsToNotifyUserForFeatureName_MockMethod: ((Bool, Feature.Name) async throws -> Void)?
    
    func storeNeedsToNotifyUser(_ notifyUser: Bool, forFeatureName name: Feature.Name) async throws {
        storeNeedsToNotifyUserForFeatureName_Invocations.append((notifyUser: notifyUser, name: name))
        
        if let error = storeNeedsToNotifyUserForFeatureName_MockError {
            throw error
        }
        
        guard let mock = storeNeedsToNotifyUserForFeatureName_MockMethod else {
            fatalError("no mock for `storeNeedsToNotifyUserForFeatureName`")
        }
        
        try await mock(notifyUser, name)
    }
    
}
