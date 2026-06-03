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

import Testing
@testable import Wire

@Suite @MainActor
struct AdminSelectionViewModelTests {

    // MARK: - filteredCandidates

    @Test(
        "filteredCandidates returns expected count",
        arguments: [
            ("", 3),
            ("alice", 1),
            ("ALICE", 1),
            ("bob", 1),
            ("@bob", 1),
            ("zzz_no_match", 0),
            ("@al", 1),
        ] as [(String, Int)]
    )
    func filteredCandidates_count(query: String, expectedCount: Int) {
        let sut = Scaffolding.makeViewModel()
        sut.searchQuery = query
        #expect(sut.filteredCandidates.count == expectedCount)
    }

    @Test(
        "filteredCandidates returns correct first candidate",
        arguments: [
            ("alice", "Alice"),
            ("ALICE", "Alice"),
            ("bob", "Bob"),
            ("@bob", "Bob"),
            ("@al", "Alice"),
        ] as [(String, String)]
    )
    func filteredCandidates_firstCandidate(query: String, expectedName: String) {
        let sut = Scaffolding.makeViewModel()
        sut.searchQuery = query
        #expect(sut.filteredCandidates.first?.name == expectedName)
    }

    // MARK: - canPromote

    @Test
    func canPromote_isFalse_initially() {
        let sut = Scaffolding.makeViewModel()
        #expect(sut.canPromote == false)
    }

    @Test
    func canPromote_isTrue_whenUserSelected() {
        let sut = Scaffolding.makeViewModel()
        sut.selectedUser = Scaffolding.candidates.first
        #expect(sut.canPromote)
    }

    @Test
    func canPromote_isFalse_afterDeselectingUser() {
        let sut = Scaffolding.makeViewModel()
        sut.selectedUser = Scaffolding.candidates.first
        sut.selectedUser = nil
        #expect(sut.canPromote == false)
    }

    @Test
    func canPromote_isFalse_whileInProgress() {
        let sut = Scaffolding.makeViewModel()
        sut.selectedUser = Scaffolding.candidates.first
        sut.promotionState = .inProgress
        #expect(sut.canPromote == false)
    }

    // MARK: - promote

    @Test
    func promote_callsOnPromoteWithCorrectUser() async {
        var invokedUser: UserType?
        let sut = Scaffolding.makeViewModel(onPromote: { user in invokedUser = user })
        let user = Scaffolding.candidates[0]
        await sut.promote(user: user)
        #expect(invokedUser?.remoteIdentifier == user.remoteIdentifier)
    }

    @Test
    func promote_setsStateToSucceeded_onSuccess() async {
        let sut = Scaffolding.makeViewModel()
        await sut.promote(user: Scaffolding.candidates[0])
        #expect(sut.promotionState == .succeeded)
    }

    @Test
    func promote_setsStateToFailed_onFailure() async {
        enum TestError: Error { case failed }
        let sut = Scaffolding.makeViewModel(onPromote: { _ in throw TestError.failed })
        await sut.promote(user: Scaffolding.candidates[0])
        #expect(sut.promotionState == .failed)
        #expect(sut.showPromotionError)
    }
}

// MARK: - Scaffolding

private extension AdminSelectionViewModelTests {

    enum Scaffolding {

        static let candidates: [UserType] = {
            let alice = MockUserType.createUser(name: "Alice")
            alice.handle = "alice"

            let bob = MockUserType.createUser(name: "Bob")
            bob.handle = "bob"

            let carol = MockUserType.createUser(name: "Carol")
            carol.handle = "carol"

            return [alice, bob, carol]
        }()

        @MainActor
        static func makeViewModel(
            onPromote: @escaping @MainActor (UserType) async throws -> Void = { _ in }
        ) -> AdminSelectionViewModel {
            AdminSelectionViewModel(
                candidates: candidates,
                userSession: UserSessionMock(),
                onPromote: onPromote
            )
        }
    }
}
