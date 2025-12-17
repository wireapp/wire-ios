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

// sourcery: AutoMockable
public protocol MLSServiceInterface: MLSEncryptionServiceInterface, MLSDecryptionServiceInterface {

    // MARK: - Managing groups

    /// Creates a new group or subgroup with the given ID.
    ///
    /// - Parameters:
    ///   - groupID: The ID of the group or subgroup to create.
    ///   - parentGroupID: The ID of the parent group, if any.
    /// - Returns: The ciphersuite used to create the group
    /// - Throws: A ``MLSService/MLSGroupCreationError`` error if the group creation fails,
    ///  or if the ciphersuite is invalid, or if the external senders cannot be fetched.
    ///
    /// The group will be created with the default ciphersuite and external senders.
    ///
    /// The external senders will be the same as the parent group.
    ///
    /// If E2EI is enabled, the creator credential type will be set to `.x509`. Otherwise, it will be set to `.basic`
    ///
    /// Once the group is created, the stale key material detector will be notified
    /// through ``StaleMLSKeyDetector/keyingMaterialUpdated(for:)``.

    func createGroup(
        for groupID: MLSGroupID,
        parentGroupID: MLSGroupID
    ) async throws -> MLSCipherSuite

    ///  Creates a new group or subgroup with the given ID.
    ///
    /// - Parameters:
    ///   - groupID: The ID of the group or subgroup to create.
    ///   - removalKeys:  External senders.
    /// - Returns: The ciphersuite used to create the group
    /// - Throws: A ``MLSService/MLSGroupCreationError`` error if the group creation fails,
    ///  or if the ciphersuite is invalid, or if the external senders cannot be fetched.
    ///
    /// If external senders are provided, the group will be created with them.
    /// Otherwise, the external senders will be fetched from the backend.

    func createGroup(
        for groupID: MLSGroupID,
        removalKeys: BackendMLSPublicKeys?
    ) async throws -> MLSCipherSuite

    /// Creates a group for the self user and adds its clients to it.
    ///
    /// - Parameter groupID: The ID of the group to create
    /// - Returns: The ciphersuite used to create the group
    /// - Throws: An error if the group cannot be created
    ///
    /// Calls ``MLSService/createGroup(for:parentGroupID:)`` to create the group.
    ///
    /// Then calls ``MLSService/addMembersToConversation(with:for:)`` to add the self user's clients to the group.
    ///
    /// If it catches ``MLSService/MLSAddMembersError/noMembersToAdd``
    /// it will update the key material to send a commit to the backend and advance to a new epoch.
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/791412993/Use+case+join+self+conversation+MLS)

    func createSelfGroup(for groupID: MLSGroupID) async throws -> MLSCipherSuite

    /// Creates a new group with the given ID and adds users to it
    ///
    /// - Parameters:
    ///   - groupID: The ID of the group to create
    ///   - users: The users to add to the group
    ///   - removalKeys: External senders
    /// - Returns: The ciphersuite used to create the group
    /// - Throws: An error if the group creation fails or if adding users fails
    ///
    /// Calls ``MLSService/createGroup(for:parentGroupID:)`` to create the group,
    /// then calls ``MLSService/addMembersToConversation(with:for:)`` to add the users and the self user.
    ///
    /// If group creation fails, it wipes the group using ``MLSService/wipeGroup(_:)``
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/557220341/Use+case+create+a+group+conversation+MLS)

    func establishGroup(
        for groupID: MLSGroupID,
        with users: [MLSUser],
        removalKeys: BackendMLSPublicKeys?
    ) async throws -> MLSCipherSuite

    /// Establishes group and sets its status to 'ready'
    /// - Parameters:
    ///   - groupID: The ID of the group to create
    func establishPendingGroup(
        groupID: MLSGroupID
    ) async throws

    /// Joins a group by external commit, for the self client.
    ///
    /// - Parameter groupID: The ID of the group to join
    /// - Throws: An error if the group cannot be joined
    ///
    /// Fetches the group info of the group from the backend,
    /// and calls ``MLSActionExecutor/joinGroup(_:groupInfo:)`` to send a commit to join the group.
    ///
    /// If the group is joined successfully, the conversation's ``ZMConversation/mlsStatus``
    /// will be set to ``MLSGroupStatus/ready``
    ///
    /// The operation is covered by a retry mechanism that will perform a recovery strategy based on errors thrown
    /// while sending commits. See `MLSService/retryOnCommitFailure(for:operation:)`
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/576454924/Use+case+join+existing+conversation+from+a+new+device+MLS)

    func joinGroup(with groupID: MLSGroupID) async throws

    /// Joins group by external commit after creating it if needed, and adds all of the self user's client to it.
    ///
    /// - Parameter groupID: The ID of the group to join
    /// - Throws: An error if the group cannot be joined
    ///
    /// Calls ``MLSService/createGroup(for:parentGroupID:)`` to create the group if it does not exist.
    /// **Note:** this may be unnecessary if we join the group via external commit, as it may implicitly create the
    /// group already.
    /// To be checked as part of [WPB-9029](https://wearezeta.atlassian.net/browse/WPB-9029)
    ///
    /// Then calls ``MLSService/joinGroup(with:)`` to join the group by external commit
    ///
    /// Finally, it adds all the clients of the self user to the group
    /// by calling ``MLSService/addMembersToConversation(with:for:)``

    func joinNewGroup(with groupID: MLSGroupID) async throws

    /// Joins the conversations for which the ``ZMConversation/mlsStatus`` is equal to ``MLSGroupStatus/pendingJoin``
    ///
    /// - Throws: An error if the pending groups fail to be fetched
    ///
    /// Starts by fetching the ``ZMConversation`` objects that have the status ``MLSGroupStatus/pendingJoin``.
    ///
    /// Then joins each conversation by external commit, similarly to ``MLSService/joinGroup(with:)``.
    /// Each conversation is joined in parallel.

    func performPendingJoins() async throws

    /// Wipes the group from core crypto's storage
    ///
    /// - Parameter groupID: The ID of the group to wipe
    /// - Throws: An error if the group cannot be wiped

    func wipeGroup(_ groupID: MLSGroupID) async throws

    func externalSenderKey(groupID: MLSGroupID) async throws -> Data

    /// Checks if the group exists in core crypto's local storage
    ///
    /// - Parameter groupID: The ID of the group to check
    /// - Returns: `true` if the group exists, `false` otherwise
    /// - Throws: An error if the check fails

    func conversationExists(groupID: MLSGroupID) async throws -> Bool

    // MARK: - Adding / Removing members

    /// Add users to a group.
    ///
    /// - Parameters:
    ///   - users: users to be added to the group
    ///   - groupID: the group ID of the conversation
    /// - Throws: an error if it fails to add members to the group
    ///
    /// Starts by commiting pending proposals by calling ``MLSService/commitPendingProposals(in:)``.
    ///
    /// Then attempts to claim the key packages of each user's clients.
    /// Then calls ``MLSActionExecutor/addMembers(_:to:)`` to send a commit bundle to the backend to add
    /// the users to the group.
    ///
    /// If there are no key packages, it will call ``MLSActionExecutor/updateKeyMaterial(for:)`` to send a commit
    /// to the backend to inform we are in the group.
    ///
    /// The operation is covered by a retry mechanism that will perform a recovery strategy based on errors thrown
    /// while sending commits. See `MLSService/retryOnCommitFailure(for:operation:)`
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/157254323/Use+case+adding+a+participant+to+a+conversation+MLS+Proteus)

    func addMembersToConversation(
        with users: [MLSUser],
        for groupID: MLSGroupID
    ) async throws

    /// Removes members (clients) from the group.
    ///
    /// - Parameters:
    ///   - clientIds: The client IDs of the members to remove
    ///   - groupID: The group ID of the conversation
    /// - Throws: an error if it fails to remove members from the group
    ///
    /// Starts by commiting pending proposals by calling ``MLSService/commitPendingProposals(in:)``.
    ///
    /// Then calls ``MLSActionExecutor/removeClients(_:from:)`` to send a commit bundle to the backend
    /// to remove the clients from the group.
    ///
    /// The operation is covered by a retry mechanism that will perform a recovery strategy based on errors thrown
    /// while sending commits. See `MLSService/retryOnCommitFailure(for:operation:)`
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/621674505/Use+case+removing+a+participant+from+a+group+MLS)

    func removeMembersFromConversation(
        with clientIds: [MLSClientID],
        for groupID: MLSGroupID
    ) async throws

    // MARK: - Managing subgroups

    /// Creates a subgroup or joins it if it already exists
    ///
    /// - Parameters:
    ///   - parentQualifiedID: The qualified ID of the parent conversation
    ///   - parentID: The group ID of the parent conversation
    /// - Returns: The group ID of the subgroup
    /// - Throws: An error if the operation fails
    ///
    /// Fetches the subgroup from the backend and caches it locally with
    /// ``SubconversationGroupIDRepository/storeSubconversationGroupID(_:forType:parentGroupID:)``
    ///
    /// If the subgroup's epoch is less than or equal to 0, it creates the subgroup
    /// similarly to ``MLSService/createGroup(for:parentGroupID:)``.
    /// After the subgroup is created it will call `updateKeyMaterial(for:)`
    /// to send a commit and update the epoch.
    /// Updating the epoch ensures other clients join the group instead of creating it.
    ///
    /// If the epoch hasn't been updated in a day, it will delete the subgroup remotely and create a new one.
    ///
    /// Otherwise, it will join the subgroup by external commit, similarly to ``MLSService/joinGroup(with:)``,
    /// except it doesn't update the conversation's ``ZMConversation/mlsStatus`` to `.ready`
    /// since it's a subgroup and the `mlsStatus` only applies to parent conversations.

    func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID

    /// Leaves the subgroup associated with the given parent conversation
    ///
    /// - Parameters:
    ///   - parentQualifiedID: The qualified ID of the parent
    ///   - parentGroupID: The group ID of the parent
    ///   - subconversationType: The subgroup type
    ///
    /// Fetches the subgroup ID based on the type and parent group IDs.
    ///
    /// It will request the backend to leave the subgroup, and if successful,
    /// remove the subgroup from the ``SubconversationGroupIDRepository``
    /// and from Core Crypto's local storage.

    func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws

    /// Leaves the subgroup if it exists locally or if the self client is a member.
    ///
    /// - Parameters:
    ///   - parentQualifiedID: The qualified ID of the parent conversation
    ///   - parentGroupID: The group ID of the parent conversation
    ///   - subconversationType: The type of subconversation
    ///   - selfClientID: The `MLSClientID` of the self client
    ///
    /// Fetches the subgroup ID based on the type and parent group IDs.
    ///
    /// If the subgroup exists locally, it leaves the subgroup.
    /// If it doesn't, it will fetch the subgroup info from the backend and leave it if the self client is a member.
    ///
    /// Leaving the subgroup entails requesting the backend to leave, and, if successful,
    /// removing the subgroup from the ``SubconversationGroupIDRepository``
    /// and from Core Crypto's local storage.

    func leaveSubconversationIfNeeded(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType,
        selfClientID: MLSClientID
    ) async throws

    /// Deletes the subgroup associated to the given parent.
    ///
    /// - Parameter parentQualifiedID: The parent conversation's qualified ID
    ///
    /// Fetches the subgroup associated to the parent conversation and deletes it.

    func deleteSubgroup(parentQualifiedID: QualifiedID) async throws

    /// Gets the list of members of a given subgroup.
    ///
    /// - Parameter subconversationGroupID: The group ID of the subgroup
    /// - Returns: An array of `MLSClientID` objects representing the members of the subgroup
    /// - Throws: ``MLSService/MLSSubconversationMembersError/failedToGetSubconversationMembers``
    ///  if the operation fails

    func subconversationMembers(for subconversationGroupID: MLSGroupID) async throws -> [MLSClientID]

    // MARK: - Pending proposals

    /// Finds groups with pending proposals and commits them if any are found.
    ///
    /// Starts by getting a list of groups that have pending proposals.
    /// This is done by fetching conversations that have a ``ZMConversation/commitPendingProposalDate`` set.
    /// We then compile the ``MLSGroupID`` of each conversation and their subconversation
    /// (if they exist) associated with the pending proposal date.
    /// The groups are then sorted by the date of the pending proposal.
    ///
    /// We then iterate through each group and check if the pending proposal date has been passed.
    /// If it has, we commit the pending proposal by calling ``MLSService/commitPendingProposals(in:)``
    /// Otherwise, we wait until the pending proposal date has passed. Then we commit the pending proposal.
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/601522340/Use+Case+Committing+pending+proposals+MLS)

    func commitPendingProposalsIfNeeded() async

    /// Commits pending proposals for a group.
    ///
    /// - Parameter groupID: The group ID to commit pending proposals for
    ///
    /// Commiting proposals entails sending a commit to the backend
    /// with ``MLSActionExecutor/commitPendingProposals(in:)``
    ///
    /// If the commit is successful, or if there are no proposals to commit,
    /// we clear the ``ZMConversation/commitPendingProposalDate``
    ///
    /// The operation is covered by a retry mechanism that will perform a recovery strategy based on errors thrown
    /// while sending commits. See `MLSService/retryOnCommitFailure(for:operation:)`

    func commitPendingProposals(in groupID: MLSGroupID) async throws

    // MARK: - Key material

    /// Updates the key material for all stale groups if it hasn't been done in the past day.
    ///
    /// Starts by calling ``StaleMLSKeyDetector/groupsWithStaleKeyingMaterial``
    /// to get the groups with stale key material.
    ///
    /// Then, for each stale group, it updates the key material
    /// by calling ``MLSActionExecutor/updateKeyMaterial(for:)``
    ///
    /// If successful it notifies that the key material has been updated
    /// via ``StaleMLSKeyDetector/keyingMaterialUpdated(for:)``
    ///
    /// Updating the key material is covered by a retry mechanism that will perform a recovery strategy
    /// based on errors thrown while sending commits.
    /// See `MLSService/retryOnCommitFailure(for:operation:)`

    func updateKeyMaterialForAllStaleGroupsIfNeeded() async

    // MARK: - Key packages

    /// Uploads new key packages if needed.
    ///
    /// To avoid making requests to the backend too frequently,
    /// we first check if more than 24 hours have passed since the last time we queried the key package count,
    /// or if the estimated local key package count is less than 50% of the target unclaimed key package count.
    ///
    /// Then we query how many key packages of the self client are available on the backend and
    /// generate and upload new ones if there are less than 50% of the target unclaimed key package count.
    ///
    /// [confluence use
    /// case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/556499553/Use+case+refill+key+packages+MLS)

    func uploadKeyPackagesIfNeeded() async

    // MARK: - Out of sync groups

    /// Fetches and re-joins MLS groups that are out of sync.
    ///
    /// Out-of-sync groups are characterized by an epoch mismatch between the epoch
    /// of the group on the backend and the epoch of the group in core crypto's local storage.
    ///
    /// Repairing out-of-sync groups is done by re-joining the group via external commit
    /// (using ``MLSService/joinGroup(with:)``.
    /// After the group is re-joined, we insert a system message indicating that
    /// there is a potential gap in the conversation history.
    ///
    /// **Note:** this method should be called after quick sync to make sure
    /// that the ``ZMConversation/epoch`` is up-to-date.
    ///
    /// [confluence use case](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/601817267/Use+Case+Detecting+and+Recovering+from+Out+of+Sync+MLS+Group)

    func repairOutOfSyncConversations() async throws

    /// Fetches and repairs the group or subgroup with the given group ID.
    ///
    /// - Parameter groupID: The group ID of the group or subgroup to repair.
    ///
    /// If the group ID corresponds to a subgroup, the parent group ID will be used to fetch the subgroup information
    /// from the backend, and it will be re-joined by external commit after checking that it is out of sync.
    ///
    /// If the group ID corresponds to a parent group, the corresponding ``ZMConversation``
    /// will be synced with the backend to ensure the epoch is up-to-date,
    /// then it will be re-joined by external commit after checking that it is out of sync.
    /// If rejoining is successful, a system message will be appended
    /// to the conversation to indicate a potential gap in history.

    func fetchAndRepairGroup(
        with groupID: MLSGroupID,
        shouldPerformIncrementalSync: Bool
    ) async

    // MARK: - Epoch

    /// Generates a new epoch by sending a commit for the given group.
    ///
    /// - Parameter groupID: The group ID for which to generate a new epoch.
    ///
    /// Commits any pending proposals before updating key material
    /// with ``MLSActionExecutor/updateKeyMaterial(for:)``,
    /// which sends a commit to the backend.
    ///
    /// Then the ``StaleMLSKeyDetector/keyingMaterialUpdated(for:)``
    /// method is called to note when the key material was updated for the group
    ///
    /// The operation is covered by a retry mechanism that will perform a recovery strategy based on errors thrown
    /// while sending commits. See `MLSService/retryOnCommitFailure(for:operation:)`

    func generateNewEpoch(groupID: MLSGroupID) async throws

    /// - Returns: A stream of epoch changes events

    func epochChanges() -> AsyncStream<MLSGroupID>

    // MARK: - Conference info

    /// Generate conference information for a given conference subconversation.
    ///
    /// - Parameters:
    ///   - parentGroupID: The group ID of the parent conversation.
    ///   - subconversationGroupID: The group ID of the subconversation in which the conference takes place.
    /// - Returns: An ``MLSConferenceInfo`` object.
    /// - Throws: ``MLSService/MLSConferenceInfoError``
    ///
    /// The conference information includes the epoch, the secret key data, and the members of the conference.

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) async throws -> MLSConferenceInfo

    /// Returns a stream of conference info changes for the given subconversation.
    ///
    /// - Parameters:
    ///   - parentGroupID: The group ID of the parent group
    ///   - subConversationGroupID: The group ID of the subgroup
    /// - Returns: A stream of conference info changes
    ///
    /// Epoch changes are observed. Each time the epoch changes, new conference info is generated.

    func onConferenceInfoChange(
        parentGroupID: MLSGroupID,
        subConversationGroupID: MLSGroupID
    ) -> AsyncThrowingStream<MLSConferenceInfo, Error>

    // MARK: - Proteus to MLS migration

    /// Starts the migration from proteus to MLS.
    ///
    /// For all team group conversations that use the proteus protocol,
    /// this method will update their ``ZMConversation/messageProtocol`` to ``MessageProtocol/mixed``
    /// and create an MLS group for them.
    /// It will then update the keying material and add all participants to the group.
    ///
    /// In case of a failure, the group will be wiped.
    ///
    /// [confluence
    /// documentation](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/746488003/Proteus+to+MLS+Migration)

    func startProteusToMLSMigration() async throws

    /// Re-establish pending group
    ///
    /// Syncs the conversation metadata and join by external commit
    /// or establish the group by adding all mls clients depending on the epoch
    /// - Parameter groupID: the mls GroupID of the conversation to re-establish
    func reEstablishPendingGroup(groupID: MLSGroupID) async throws

    // MARK: - Sync delegate

    /// Set the MLS sync delegate.
    ///
    /// - Parameter delegate: The sync delegate to set.

    func setSyncDelegate(_ delegate: any MLSSyncDelegate)

    func setResetBrokenMLSConversationDelegate(_ delegate: any ResetBrokenMLSConversationDelegate)
}
