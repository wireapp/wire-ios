//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest

public class FlakyTestDetectorSuperCaller: XCTestCaseSuperCaller {
    public enum FlakyReps {
        case fixed(repsCount: Int)
        case env(defaultRepsCount: Int)
        
        public var count: Int {
            switch self {
            case .fixed(let repsCount):
                return repsCount
            case .env(let defaultRepsCount):
                return defaultRepsCount
            }
        }
    }
    
    private let reps: FlakyReps
    
    public init(reps: FlakyReps = .env(defaultRepsCount: 20)) {
        
        self.reps = reps
    }
    
    public func callSuperInvokeTest(fire superCall: () -> Void, on testCase: XCTestCase) {
        var failureCounts: [Int] = []
        failureCounts.reserveCapacity(reps.count)
        for _ in 0...reps.count {
            let failureCountSnapshot = testCase.testRun?.totalFailureCount ?? 0
            superCall()
            let newFailureCount = testCase.testRun?.totalFailureCount ?? 0
            failureCounts.append(newFailureCount - failureCountSnapshot)
        }
        let targettedFailureCount = failureCounts.first
        let flakyDetected = !failureCounts.allSatisfy { $0 == targettedFailureCount }
        guard !flakyDetected else {
            testCase.record(XCTIssue(type: XCTIssue.IssueType.assertionFailure, compactDescription: "Flaky test detected: \(testCase.name)"))
            return
        }
    }
    
    private static func envOrGiven(reps: FlakyReps) -> FlakyReps {
        switch reps {
        case .env:
            guard let repsCountString = ProcessInfo.processInfo.environment["FLAKY_REPS_COUNT"],
                  let repsCount = Int(repsCountString)
            else {
                return reps
            }
            return .env(defaultRepsCount: repsCount > 0 ? repsCount : 1)
        case .fixed:
            return reps
        }
    }
}
