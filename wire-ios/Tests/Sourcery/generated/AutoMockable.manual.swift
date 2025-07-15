// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name


import CoreLocation
import WireDataModel
import WireSyncEngine
import WireAccountImageUI
import WireCellsAPI

@testable import Wire
@testable import WireCommonComponents

class MockGetUserByIdUseCaseProtocol: GetUserByIDUseCaseProtocol {

    // MARK: - getUserByID

    var getUserByIdIdContext_Invocations: [(id: Any, context: NSManagedObjectContext)] = []
    var getUserByIdIdContext_MockValue: (any UserType)?

    func getUserByID(id: Any, context: NSManagedObjectContext) -> (any UserType)? {
        getUserByIdIdContext_Invocations.append((id: id, context: context))

        if let mock = getUserByIdIdContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `getUserByIdIdContext`")
        }
    }

}

class MockWireCellsFactoryProtocol: WireCellsFactoryProtocol {

    // MARK: - Life cycle

    init() {}

    // MARK: - makeUploadDraftUseCase

    var makeUploadDraftUseCaseCellName_Invocations: [String] = []
    var makeUploadDraftUseCaseCellName_MockMethod: ((String) -> any WireCellsUploadDraftUseCaseProtocol)?
    var makeUploadDraftUseCaseCellName_MockValue: (any WireCellsUploadDraftUseCaseProtocol)?

    func makeUploadDraftUseCase(cellName: String) -> any WireCellsUploadDraftUseCaseProtocol {
        makeUploadDraftUseCaseCellName_Invocations.append(cellName)

        if let mock = makeUploadDraftUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeUploadDraftUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeUploadDraftUseCaseCellName`")
        }
    }

    // MARK: - makeObserveDraftsUseCase

    var makeObserveDraftsUseCaseCellName_Invocations: [String] = []
    var makeObserveDraftsUseCaseCellName_MockMethod: ((String) -> any WireCellsObserveDraftsUseCaseProtocol)?
    var makeObserveDraftsUseCaseCellName_MockValue: (any WireCellsObserveDraftsUseCaseProtocol)?

    func makeObserveDraftsUseCase(cellName: String) -> any WireCellsObserveDraftsUseCaseProtocol {
        makeObserveDraftsUseCaseCellName_Invocations.append(cellName)

        if let mock = makeObserveDraftsUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeObserveDraftsUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeObserveDraftsUseCaseCellName`")
        }
    }

    // MARK: - makePublishDraftsUseCase

    var makePublishDraftsUseCaseCellName_Invocations: [String] = []
    var makePublishDraftsUseCaseCellName_MockMethod: ((String) -> any WireCellsPublishDraftsUseCaseProtocol)?
    var makePublishDraftsUseCaseCellName_MockValue: (any WireCellsPublishDraftsUseCaseProtocol)?

    func makePublishDraftsUseCase(cellName: String) -> any WireCellsPublishDraftsUseCaseProtocol {
        makePublishDraftsUseCaseCellName_Invocations.append(cellName)

        if let mock = makePublishDraftsUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makePublishDraftsUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makePublishDraftsUseCaseCellName`")
        }
    }

    // MARK: - makeClearPublishedDraftsUseCase

    var makeClearPublishedDraftsUseCaseCellName_Invocations: [String] = []
    var makeClearPublishedDraftsUseCaseCellName_MockMethod: ((String) -> any WireCellsClearPublishedDraftsUseCaseProtocol)?
    var makeClearPublishedDraftsUseCaseCellName_MockValue: (any WireCellsClearPublishedDraftsUseCaseProtocol)?

    func makeClearPublishedDraftsUseCase(cellName: String) -> any WireCellsClearPublishedDraftsUseCaseProtocol {
        makeClearPublishedDraftsUseCaseCellName_Invocations.append(cellName)

        if let mock = makeClearPublishedDraftsUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeClearPublishedDraftsUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeClearPublishedDraftsUseCaseCellName`")
        }
    }

    // MARK: - makeDeleteDraftUseCase

    var makeDeleteDraftUseCaseCellName_Invocations: [String] = []
    var makeDeleteDraftUseCaseCellName_MockMethod: ((String) -> any WireCellsDeleteDraftUseCaseProtocol)?
    var makeDeleteDraftUseCaseCellName_MockValue: (any WireCellsDeleteDraftUseCaseProtocol)?

    func makeDeleteDraftUseCase(cellName: String) -> any WireCellsDeleteDraftUseCaseProtocol {
        makeDeleteDraftUseCaseCellName_Invocations.append(cellName)

        if let mock = makeDeleteDraftUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeDeleteDraftUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeDeleteDraftUseCaseCellName`")
        }
    }

    // MARK: - makeRetryUploadDraftUseCase

    var makeRetryUploadDraftUseCaseCellName_Invocations: [String] = []
    var makeRetryUploadDraftUseCaseCellName_MockMethod: ((String) -> any WireCellsRetryUploadDraftUseCaseProtocol)?
    var makeRetryUploadDraftUseCaseCellName_MockValue: (any WireCellsRetryUploadDraftUseCaseProtocol)?

    func makeRetryUploadDraftUseCase(cellName: String) -> any WireCellsRetryUploadDraftUseCaseProtocol {
        makeRetryUploadDraftUseCaseCellName_Invocations.append(cellName)

        if let mock = makeRetryUploadDraftUseCaseCellName_MockMethod {
            return mock(cellName)
        } else if let mock = makeRetryUploadDraftUseCaseCellName_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeRetryUploadDraftUseCaseCellName`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
