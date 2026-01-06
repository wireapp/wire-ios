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

struct EnvironmentVariables {
    enum Failure: Error {
        case missingBackendURL
        case missingInbucketURL
        case missingInbucketUsername
        case missingInbucketPassword
        case missingDeepLinkURL
    }

    private let stagingBackendURL: URL
    private let antaBackendURL: URL

    private let stagingInbucketURL: URL
    private let antaInbucketURL: URL

    let antaDeepLinkURL: URL

    let inbucketUsername: String
    let inbucketPassword: String

    init() throws {
        guard let backendURLString = ProcessInfo.processInfo.environment["BACKEND_URL"],
              !backendURLString.isEmpty else {
            throw Failure.missingBackendURL
        }
        guard let inbucketHostname = ProcessInfo.processInfo.environment["INBUCKET_URL"],
              !inbucketHostname.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let inbucketUsername = ProcessInfo.processInfo.environment["INBUCKET_USERNAME"],
              !inbucketUsername.isEmpty else {
            throw Failure.missingInbucketUsername
        }

        guard let inbucketPassword = ProcessInfo.processInfo.environment["INBUCKET_PASSWORD"],
              !inbucketPassword.isEmpty else {
            throw Failure.missingInbucketUsername
        }

        guard let antaDeeplinkURL = ProcessInfo.processInfo.environment["ANTA_DEEPLINK_URL"],
              !antaDeeplinkURL.isEmpty else {
            throw Failure.missingDeepLinkURL
        }

        guard let antaInbucketURL = ProcessInfo.processInfo.environment["ANTA_INBUCKET_URL"],
              !antaInbucketURL.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let backendURLAntaString = ProcessInfo.processInfo.environment["BACKEND_URL_ANTA"],
              !backendURLAntaString.isEmpty else {
            throw Failure.missingBackendURL
        }

        self.stagingBackendURL = URL(string: "https://\(backendURLString)")!
        self.stagingInbucketURL = URL(string: "https://\(inbucketHostname)")!
        self.inbucketUsername = inbucketUsername
        self.inbucketPassword = inbucketPassword
        self.antaDeepLinkURL = URL(string: "https://\(antaDeeplinkURL)")!
        self.antaInbucketURL = URL(string: "https://\(antaInbucketURL)")!
        self.antaBackendURL = URL(string: "https://\(backendURLAntaString)")!
    }

    var inbucketURL: URL {
        switch BackendContext.current {
        case .anta:
            antaInbucketURL
        case .staging:
            stagingInbucketURL
        }
    }

    var backendURL: URL {
        switch BackendContext.current {
        case .anta:
            antaBackendURL
        case .staging:
            stagingBackendURL
        }
    }

    func deepLinkURL(for target: BackendTarget) -> URL {
        switch target {
        case .anta:
            antaDeepLinkURL
        case .staging:
            fatalError("Not implemented yet")
        }
    }

}
