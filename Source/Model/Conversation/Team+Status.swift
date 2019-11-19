//
//  Team+Status.swift
//  WireDataModel
//
//  Created by David Henner on 19.11.19.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension Team {
    public static let membersOptimalLimit = 400
    
    public var shouldCommunicateStatus: Bool {
        return self.members.count < Team.membersOptimalLimit
    }
}
