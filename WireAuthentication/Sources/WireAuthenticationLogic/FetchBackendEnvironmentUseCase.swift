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
import WireAPI
import WireAuthenticationAPI
import WireLogging

public struct FetchBackendEnvironmentUseCase: FetchBackendEnvironmentUseCaseProtocol {

    public init() {}

    public func invoke(at configURL: URL) async throws(FetchBackendEnvironmentFailure) -> BackendEnvironmentResponse {
        do {
            let environmentResponse = try await fetchEnvironment(url: configURL)
            return environmentResponse
        } catch let error as FetchBackendEnvironmentFailure {
            throw error
        } catch {
            throw FetchBackendEnvironmentFailure.unknown
        }
    }

    private func fetchEnvironment(url: URL) async throws -> BackendEnvironmentResponse {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let environmentResponse = try decoder.decode(BackendEnvironmentResponse.self, from: data)
            WireLogger.backend.info("Fetched custom configuration from \(url)")

            return environmentResponse
        } catch let decodingError as DecodingError {
            WireLogger.backend.info("Error decoding response from \(url): \(decodingError)")
            throw FetchBackendEnvironmentFailure.invalidResponse
        } catch {
            WireLogger.backend.error("Error fetching configuration from \(url): \(error)")
            throw FetchBackendEnvironmentFailure.requestFailed
        }
    }

}
