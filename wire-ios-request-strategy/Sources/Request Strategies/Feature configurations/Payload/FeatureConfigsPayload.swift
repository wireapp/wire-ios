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

struct FeatureConfigsPayload: Decodable {

    let appLock: FeatureStatusWithConfig<Feature.AppLock.Config>?
    let classifiedDomains: FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>?
    let conferenceCalling: FeatureStatus?
    let conversationGuestLinks: FeatureStatus?
    let digitalSignatures: FeatureStatus?
    let fileSharing: FeatureStatus?
    let mls: FeatureStatusWithConfig<Feature.MLS.Config>?
    let selfDeletingMessages: FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>?
    let mlsMigration: FeatureStatusWithConfig<Feature.MLSMigration.Config>?
    let mlsE2EId: FeatureStatusWithConfig<Feature.E2EI.Config>?

}

struct FeatureConfigsPayloadAPIV6: Decodable {

    let appLock: FeatureStatusWithConfig<Feature.AppLock.Config>?
    let classifiedDomains: FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>?
    let conferenceCalling: FeatureStatusWithConfig<Feature.ConferenceCalling.Config>?
    let conversationGuestLinks: FeatureStatus?
    let digitalSignatures: FeatureStatus?
    let fileSharing: FeatureStatus?
    let mls: FeatureStatusWithConfig<Feature.MLS.Config>?
    let selfDeletingMessages: FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>?
    let mlsMigration: FeatureStatusWithConfig<Feature.MLSMigration.Config>?
    let mlsE2EId: FeatureStatusWithConfig<Feature.E2EI.Config>?

}

struct FeatureStatus: Decodable {
    let status: Feature.Status
}

struct FeatureStatusWithConfig<Config: Codable>: Decodable {
    let status: Feature.Status
    let config: Config
}
