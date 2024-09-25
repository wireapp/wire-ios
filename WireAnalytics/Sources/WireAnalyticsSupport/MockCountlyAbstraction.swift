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

import WireAnalytics

public class MockCountlyAbstraction: CountlyAbstraction {
    public typealias CountlyUserDetails = MockCountlyUserDetailsAbstraction
    public typealias CountlyConfig = MockCountlyConfigAbstraction


    // MARK: - Life cycle

    required public init() {}

    // MARK: - sharedInstance

    public var sharedInstance_Invocations: [Void] = []
    public var sharedInstance_MockMethod: (() -> MockCountlyAbstraction)?
    public var sharedInstance_MockValue: MockCountlyAbstraction?

    static public func sharedInstance() -> Self {
        fatalError("no mock for `sharedInstance`")
    }

    // MARK: - user

    class public func user() -> MockCountlyUserDetailsAbstraction {
        fatalError("no mock for `user`")
    }

    // MARK: - start

    public var startWith_Invocations: [CountlyConfig] = []
    public var startWith_MockMethod: ((CountlyConfig) -> Void)?

    public func start(with config: CountlyConfig) {
        startWith_Invocations.append(config)

        guard let mock = startWith_MockMethod else {
            fatalError("no mock for `startWith`")
        }

        mock(config)
    }

    // MARK: - setNewDeviceID

    public var setNewDeviceIDOnServer_Invocations: [(deviceID: String?, onServer: Bool)] = []
    public var setNewDeviceIDOnServer_MockMethod: ((String?, Bool) -> Void)?

    public func setNewDeviceID(_ deviceID: String?, onServer: Bool) {
        setNewDeviceIDOnServer_Invocations.append((deviceID: deviceID, onServer: onServer))

        guard let mock = setNewDeviceIDOnServer_MockMethod else {
            fatalError("no mock for `setNewDeviceIDOnServer`")
        }

        mock(deviceID, onServer)
    }

    // MARK: - changeDeviceID

    public var changeDeviceIDWithMerge_Invocations: [String?] = []
    public var changeDeviceIDWithMerge_MockMethod: ((String?) -> Void)?

    public func changeDeviceID(withMerge id: String?) {
        changeDeviceIDWithMerge_Invocations.append(id)

        guard let mock = changeDeviceIDWithMerge_MockMethod else {
            fatalError("no mock for `changeDeviceIDWithMerge`")
        }

        mock(id)
    }

    // MARK: - changeDeviceIDWithoutMerge

    public var changeDeviceIDWithoutMerge_Invocations: [String?] = []
    public var changeDeviceIDWithoutMerge_MockMethod: ((String?) -> Void)?

    public func changeDeviceIDWithoutMerge(_ id: String?) {
        changeDeviceIDWithoutMerge_Invocations.append(id)

        guard let mock = changeDeviceIDWithoutMerge_MockMethod else {
            fatalError("no mock for `changeDeviceIDWithoutMerge`")
        }

        mock(id)
    }

    // MARK: - beginSession

    public var beginSession_Invocations: [Void] = []
    public var beginSession_MockMethod: (() -> Void)?

    public func beginSession() {
        beginSession_Invocations.append(())

        guard let mock = beginSession_MockMethod else {
            fatalError("no mock for `beginSession`")
        }

        mock()
    }

    // MARK: - updateSession

    public var updateSession_Invocations: [Void] = []
    public var updateSession_MockMethod: (() -> Void)?

    public func updateSession() {
        updateSession_Invocations.append(())

        guard let mock = updateSession_MockMethod else {
            fatalError("no mock for `updateSession`")
        }

        mock()
    }

    // MARK: - endSession

    public var endSession_Invocations: [Void] = []
    public var endSession_MockMethod: (() -> Void)?

    public func endSession() {
        endSession_Invocations.append(())

        guard let mock = endSession_MockMethod else {
            fatalError("no mock for `endSession`")
        }

        mock()
    }

    // MARK: - recordEvent

    public var recordEventSegmentation_Invocations: [(name: String, segmentation: [String: String]?)] = []
    public var recordEventSegmentation_MockMethod: ((String, [String: String]?) -> Void)?

    public func recordEvent(_ name: String, segmentation: [String: String]?) {
        recordEventSegmentation_Invocations.append((name: name, segmentation: segmentation))

        guard let mock = recordEventSegmentation_MockMethod else {
            fatalError("no mock for `recordEventSegmentation`")
        }

        mock(name, segmentation)
    }

}
