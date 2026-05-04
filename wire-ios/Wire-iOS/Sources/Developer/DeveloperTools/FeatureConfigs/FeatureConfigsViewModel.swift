//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireDomain
import WireSyncEngine

final class FeatureConfigsViewModel: ObservableObject {

    struct Item: Identifiable {
        let featureConfigName: Feature.Name
        let enabled: Bool

        var id: String {
            featureConfigName.rawValue
        }
    }

    @Published var items: [Item] = []
    private let store: FeatureConfigLocalStore

    init(context: NSManagedObjectContext) {
        self.store = FeatureConfigLocalStore(context: context)
    }

    @MainActor
    func fetchFeatureConfigs() async {
        var items = [Item]()
        for featureName in Feature.Name.allCases {
            guard let feature = try? await store.fetchFeature(name: featureName) else {
                continue
            }
            items.append(
                .init(
                    featureConfigName: featureName,
                    enabled: await store.isFeatureEnabled(feature: feature)
                )
            )
        }

        self.items = items
    }
}
