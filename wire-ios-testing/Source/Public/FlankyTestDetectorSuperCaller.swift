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

public class FlankyTestDetectorSuperCaller: XCTestCaseSuperCaller {    
    public enum FlankyReps {
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
    
    private let reps: FlankyReps
    
    public init(reps: FlankyReps = .env(defaultRepsCount: 5)) {
        
        self.reps = reps
    }
    
    public func callSuperInvokeTest<TestCase: XCTestCase>(fire method: () -> Void, on testCase: TestCase) {
        var failureCounts: [Int] = []
        failureCounts.reserveCapacity(reps.count)
        for _ in 0...reps.count {
            let failureCountSnapshot = testCase.testRun?.totalFailureCount ?? 0
            callSuper(fire: method, on: testCase)
            let newFailureCount = testCase.testRun?.totalFailureCount ?? 0
            failureCounts.append(newFailureCount - failureCountSnapshot)
        }
        let targettedFailureCount = failureCounts.first
        let flankyDetected = !failureCounts.allSatisfy { $0 == targettedFailureCount }
        guard !flankyDetected else {
            testCase.record(XCTIssue(type: XCTIssue.IssueType.assertionFailure, compactDescription: "Flanky test detected in: \(testCase.name)"))
            return
        }
    }
    
    private static func envOrGiven(reps: FlankyReps) -> FlankyReps {
        switch reps {
        case .env:
            guard let repsCountString = ProcessInfo.processInfo.environment["FLANKY_REPS_COUNT"],
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
