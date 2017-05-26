//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel

extension ZMTransportResponse {
    static let teamNotFound = ZMTransportResponse(payload: ["label" : "no-team"] as ZMTransportData, httpStatus: 404, transportSessionError: nil)
    static let notTeamMember = ZMTransportResponse(payload: ["label" : "no-team-member"] as ZMTransportData, httpStatus: 403, transportSessionError: nil)
    static let operationDenied = ZMTransportResponse(payload: ["label" : "operation-denied"] as ZMTransportData, httpStatus: 403, transportSessionError: nil)
}

extension MockTransportSession {
    @objc(processTeamsRequest:)
    public func processTeamsRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        var response: ZMTransportResponse?
        
        switch request {
        case "/teams":
            response = fetchAllTeams(query: request.queryParameters)
        case "/teams/*":
            response = fetchTeam(with: request.RESTComponents(index: 1))
        case "/teams/*/members":
            response = fetchMembersForTeam(with: request.RESTComponents(index: 1))
        default:
            break
        }

        if let response = response {
            return response
        } else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
    }
    
    private func fetchTeam(with identifier: String?) -> ZMTransportResponse? {
        guard let identifier = identifier else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: identifier)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound }
        if let permissionError = ensurePermission([], in: team) {
            return permissionError
        }
        return ZMTransportResponse(payload: team.payload, httpStatus: 200, transportSessionError: nil)
    }
    
    private func fetchAllTeams(query: [String : Any]) -> ZMTransportResponse? {
        var predicate: NSPredicate?
        if let ids = query["ids"] as? String {
            let teamIds = ids.components(separatedBy: ",")
            predicate = NSPredicate(format: "%K in %@", #keyPath(MockTeam.identifier), teamIds)
        }
        
        let sortDescriptors = [NSSortDescriptor(key: #keyPath(MockTeam.createdAt), ascending: true)]
        let allTeams: [MockTeam] = MockTeam.fetchAll(in: managedObjectContext, withPredicate: predicate, sortBy: sortDescriptors)
        
        let startTeam = query["start"] as? String
        var size: Int?
        if let sizeString = query["size"] as? String {
            size = Int(sizeString)
        }
        
        let (teams, hasMore) = paginate(teams: allTeams, start: startTeam, size: size)
        let payload: [String : Any] = [
            "teams" : teams.map { $0.payload },
            "has_more" : hasMore
        ]
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
    }
    
    private func paginate(teams: [MockTeam], start: String?, size: Int?) -> ([MockTeam], Bool) {
        var startTeamIndex: Int?
        if let start = start {
            for (idx, team) in teams.enumerated() {
                if team.identifier == start {
                    if idx + 1 < teams.count {
                        startTeamIndex = idx + 1
                    } else {
                        startTeamIndex = teams.count - 1
                    }
                    break
                }
            }
            // The queried team was not found
            if startTeamIndex == nil {
                return ([], false)
            }
        }
        
        let teamsFrom = startTeamIndex ?? 0
        let teamsSize = size ?? 100
        let paginatedTeams = teams.suffix(from: teamsFrom).prefix(teamsSize)
        
        let hasMore = !paginatedTeams.isEmpty && (teams.last != paginatedTeams.last)
        return (Array(paginatedTeams), hasMore)
    }
    
    private func fetchMembersForTeam(with identifier: String?) -> ZMTransportResponse? {
        guard let identifier = identifier else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: identifier)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound }
        if let permissionError = ensurePermission(.getMemberPermissions, in: team) {
            return permissionError
        }
        
        let payload: [String : Any] = [
            "members" : team.members.map { $0.payload }
        ]

        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
    }
    
    private func ensurePermission(_ permissions: Permissions, in team: MockTeam) -> ZMTransportResponse? {
        guard let selfTeams = selfUser.memberships,
            let member = selfTeams.union(team.members).first
            else { return .notTeamMember }
        
        guard member.permissions.contains(permissions) else {
            return .operationDenied
        }
        // All good, no error returned
        return nil
    }
    
}
