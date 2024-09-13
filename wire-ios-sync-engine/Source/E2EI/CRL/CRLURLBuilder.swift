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

/// Depending on the `mlsE2EId` feature flag configuration, we should use a CRL proxy or fetching the CRL directly.
/// https://wearezeta.atlassian.net/wiki/spaces/PAD/pages/1147666542/2024-04-22+CRL+proxy+for+mobile+apps
struct CRLURLBuilder {
    private let shouldUseProxy: Bool
    private let proxyURL: URL?

    init(shouldUseProxy: Bool, proxyURLString: String?) {
        self.shouldUseProxy = shouldUseProxy

        guard let proxyURLString else {
            self.proxyURL = nil
            return
        }
        self.proxyURL = URL(string: proxyURLString)
    }

    func getURL(from distributionPoint: URL) -> URL {
        guard let proxyURL, shouldUseProxy else {
            return distributionPoint
        }

        return constructProxyCrlURL(from: distributionPoint, proxyURL: proxyURL)
    }

    // MARK: - Private methods

    private func constructProxyCrlURL(from distributionPoint: URL, proxyURL: URL) -> URL {
        let distributionPointComponents = URLComponents(url: distributionPoint, resolvingAgainstBaseURL: false)

        return proxyURL.appendingPathComponent(distributionPointComponents?.host ?? "")
    }
}
