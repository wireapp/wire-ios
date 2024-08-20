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

import Foundation

import Foundation
import WireAPI
import WireDataModel

/// Facilitate access to feature configs related domain objects.

protocol FeatureConfigRepositoryProtocol {

    /// Pull feature configs from the server and store locally.

    func pullFeatureConfigs() async throws
}

struct FeatureConfigRepository: FeatureConfigRepositoryProtocol {
    
    private let featureConfigsAPI: any FeatureConfigsAPI
    private let context: NSManagedObjectContext
    
    init(
        featureConfigsAPI: any FeatureConfigsAPI,
        context: NSManagedObjectContext
    ) {
        self.featureConfigsAPI = featureConfigsAPI
        self.context = context
    }
    
    func pullFeatureConfigs() async throws {
        let featureConfigs = try await featureConfigsAPI.getFeatureConfigs()
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for featureConfig in featureConfigs {
                taskGroup.addTask {
                    try await storeFeatureConfig(featureConfig)
                }
            }
        }
    }
    
    private func storeFeatureConfig(_ featureConfig: FeatureConfig) async throws {
//        switch featureConfig {
//        case .appLock(let appLockFeatureConfig):
//            
//        case .classifiedDomains(let classifiedDomainsFeatureConfig):
//            <#code#>
//        case .conferenceCalling(let conferenceCallingFeatureConfig):
//            
//        case .conversationGuestLinks(let conversationGuestLinksFeatureConfig):
//            <#code#>
//        case .digitalSignature(let digitalSignatureFeatureConfig):
//            <#code#>
//        case .endToEndIdentity(let endToEndIdentityFeatureConfig):
//            <#code#>
//        case .fileSharing(let fileSharingFeatureConfig):
//            <#code#>
//        case .mls(let mLSFeatureConfig):
//            <#code#>
//        case .mlsMigration(let mLSMigrationFeatureConfig):
//            <#code#>
//        case .selfDeletingMessages(let selfDeletingMessagesFeatureConfig):
//            <#code#>
//        case .unknown(let featureName):
//            <#code#>
//        }
    }
}
