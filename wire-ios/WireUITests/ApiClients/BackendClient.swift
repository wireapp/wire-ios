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
import WireNetwork

enum BackendClient {

    static var apiVersion: APIVersion = .v8
    static let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"

    static func loginViaAPI(email: String, password: String) async throws -> String {
        let envVariables = try EnvironmentVariables()
        let requestUrl = envVariables.backendURL.appending(path: "v8/login")

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        let body: [String: Any] = ["email": "\(email)", "password": "\(password)"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let message: LoginMessage = try JSONDecoder().decode(LoginMessage.self, from: responseData)
        return message.access_token
    }

    static func deletePersonalUser(access_token: String, password: String) async throws {
        let envVariables = try EnvironmentVariables()
        let requestUrl = envVariables.backendURL.appending(path: "self")

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "DELETE"
        let body: [String: Any] = ["password": "\(password)"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }
    }

    static func getActivationCode(email: String) async throws -> (code: String, key: String) {
        let url = URL(string: "\(backendURL)/i/users/activation-code?email=\(email)")
        let auth = ProcessInfo.processInfo.environment["BASIC_AUTH"]!
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(auth)", forHTTPHeaderField: "Authorization")

        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {

            throw RuntimeError("Error \(pureResponse.description)")

        }

        let message: ActivationCodeReponse = try JSONDecoder().decode(ActivationCodeReponse.self, from: responseData)
        return (message.code, message.key)
    }

    static func sendVerificationCode(email: String, password: String) async throws {
        let access_token = try await loginViaAPI(email: email, password: password)
        let body: [String: Any] = [
            "action": "delete_team",
            "email": email
        ]

        let url = URL(string: "\(backendURL)/\(apiVersion)/verification-code/send")
        guard let requestUrl = url else { fatalError() }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }
    }

    static func registerPersonalUser(_ user: UserInfo) async throws -> UserInfo {
        let body: [String: Any] = [
            "email": user.email,
            "password": user.password,
            "name": user.name
        ]
        let response = try await httpPostRequest(url: "\(backendURL)/register", body: body)
        let userData: UserResponse = try JSONDecoder().decode(UserResponse.self, from: response)
        let updatedUser = UserInfo()
        updatedUser.name = userData.name
        updatedUser.email = userData.email
        updatedUser.id = userData.id

        updatedUser.backendDomain = userData.qualified_id.domain
        return updatedUser
    }

    private static func httpPostRequest(url: String, body: [String: Any]) async throws -> Data {
        guard let requestUrl = URL(string: url) else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 201 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
        return responseData
    }

    static func getTeamIDFromSelfRequest(email: String, password: String) async throws -> UUID? {
        let access_token = try await loginViaAPI(email: email, password: password)

        let envVariables = try EnvironmentVariables()
        let requestUrl = envVariables.backendURL.appending(path: "v8/self")

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }

        let userData: SelfAPIResponse = try JSONDecoder().decode(SelfAPIResponse.self, from: responseData)
        return userData.team
    }

    static func upgradePersonalToTeam(email: String, password: String, teamName: String) async throws -> UUID {
        let access_token = try await loginViaAPI(email: email, password: password)
        let body: [String: Any] = [
            "icon": "default",
            "name": teamName
        ]

        let url = URL(string: "\(backendURL)/upgrade-personal-to-team")
        guard let requestUrl = url else { fatalError() }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")

        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let userData: PersonalToTeamResponse = try JSONDecoder().decode(PersonalToTeamResponse.self, from: responseData)
        return userData.team_id

    }

    static func inviteUserToTeam(
        teamID: UUID,
        email: String,
        password: String,
        memberName: String,
        memberEmail: String
    ) async throws -> UUID {
        let access_token = try await loginViaAPI(email: email, password: password)
        let body: [String: Any] = [
            "email": memberEmail,
            "name": memberName,
            "role": "member"
        ]

        let envVariables = try EnvironmentVariables()
        let requestUrl = envVariables.backendURL.appending(path: "/\(apiVersion)/teams/\(teamID)/invitations")

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")

        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 201 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let userData: InviteUserToTeamResponse = try JSONDecoder().decode(
            InviteUserToTeamResponse.self,
            from: responseData
        )
        return userData.id
    }

    static func getInvitationCode(team: UUID, invitationID: UUID) async throws -> String {
        let url = URL(string: "\(backendURL)/i/teams/invitation-code?team=\(team)&invitation_id=\(invitationID)")
        let auth = ProcessInfo.processInfo.environment["BASIC_AUTH"]!
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(auth)", forHTTPHeaderField: "Authorization")

        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {

            throw RuntimeError("Error \(pureResponse.description)")

        }

        let message: InvitationCodeReponse = try JSONDecoder().decode(InvitationCodeReponse.self, from: responseData)
        return message.code
    }

    static func registerTeamMember(
        _ memberUser: UserInfo, invitationCode: String
    ) async throws {
        let body: [String: Any] = [
            "email": memberUser.email,
            "password": memberUser.password,
            "name": memberUser.email,
            "team_code": invitationCode
        ]

        _ = try await httpPostRequest(url: "\(backendURL)/register", body: body)
    }

}

private struct LoginMessage: Decodable {
    let access_token: String
}

private struct UserResponse: Decodable {
    let email: String
    let id: String
    let name: String
    let qualified_id: QualifiedID
}

private struct QualifiedID: Decodable {
    let domain: String
    let id: String
}

private struct ActivationCodeReponse: Decodable {
    let code: String
    let key: String
}

private struct SelfAPIResponse: Decodable {
    let team: UUID?
}

private struct PersonalToTeamResponse: Decodable {
    let team_id: UUID
}

private struct InviteUserToTeamResponse: Decodable {
    let id: UUID
}

private struct InvitationCodeReponse: Decodable {
    let code: String
}
