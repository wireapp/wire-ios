package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.CommonSteps;
import com.wearezeta.auto.common.backend.Backend;
import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.backend.models.MuteState;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

import java.io.ByteArrayInputStream;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.time.Duration;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static org.hamcrest.Matchers.containsString;

public class CommonBackendSteps {

    IOSTestContext context;

    public CommonBackendSteps(IOSTestContext context) {
        this.context = context;
    }

    private CommonSteps getCommonSteps() {
        return context.getCommonSteps();
    }

    private List<String> userGetDeviceIds(String usernameAlias) {
        return context.getCommonSteps().getDeviceIds(usernameAlias);
    }

    @When("^User (.*) blocks user (.*)$")
    public void BlockContact(String blockAsUserNameAlias, String userToBlockNameAlias) {
        getCommonSteps().blockContact(blockAsUserNameAlias, userToBlockNameAlias);
    }

    @Given("^(\\w+) waits? until (\\w+) exists in backend search results$")
    public void UserWaitsUntilContactExistsInHisSearchResults(
            String searchByNameAlias, String query) {
        getCommonSteps().waitUntilContactIsFoundInSearch(searchByNameAlias, query);
    }

    @Given("^User (.*) removes their avatar picture$")
    public void UserRemovesAvatarPicture(String nameAlias) {
        getCommonSteps().userDeletesAvatarPicture(nameAlias);
    }

    @Given("^User (.*) removes all their registered OTR clients$")
    public void UserRemovesAllRegisteredOtrClients(String userAs) {
        getCommonSteps().userRemovesAllRegisteredOtrClients(userAs);
    }

    @When("^User (.*) cancels all outgoing connection requests$")
    public void CancelAllOutgoingConnectRequest(String userToNameAlias) {
        getCommonSteps().cancelAllOutgoingConnectRequests(userToNameAlias);
    }

    @Given("^User (.*) sent connection request to (.*)$")
    public void GivenConnectionRequestIsSentTo(String userFromNameAlias, String usersToNameAliases) {
        getCommonSteps().connectionRequestIsSentTo(userFromNameAlias, usersToNameAliases);
    }

    @Given("^User (.*) has group conversation (.*) with (.*)$")
    public void UserHasGroupChatWithContacts(String chatOwnerNameAlias,
                                             String chatName, String otherParticipantsNameAlises) {
        getCommonSteps().userHasGroupChatWithContacts(chatOwnerNameAlias, chatName, otherParticipantsNameAlises);
    }

    @When("^User (.*) adds (.*) to group chat (.*)")
    public void UserXDddsUserYToGroupChat(String chatOwnerNameAlias,
                                          String userToAdd, String chatName) {
        getCommonSteps().userXAddedContactsToGroupChat(chatOwnerNameAlias, userToAdd, chatName);
    }

    @Given("^User (.*) is connected to (.*)$")
    public void UserIsConnectedTo(String userFromNameAlias, String usersToNameAliases) {
        getCommonSteps().userIsConnectedTo(userFromNameAlias, usersToNameAliases);
    }

    @Given("^User (.*) accepts connection request from (.*)")
    public void acceptConnectionRequestFrom(String asUserAlias, String userFromNameAliases) {
        context.getCommonSteps().userAcceptsConnectionRequestFrom(asUserAlias, userFromNameAliases);
    }

    @Given("^User (.*) leaves group chat (.*)$")
    public void UserLeavesGroupChat(String userName, String chatName) {
        getCommonSteps().userXLeavesGroupChat(userName, chatName);
    }

    @Given("^User (.*) removes? user (.*) from group conversation (.*)$")
    public void UserARemovesUserBFromGroupChat(String chatOwnerNameAlias, String userToRemove, String chatName) {
        getCommonSteps().userXRemoveUserFromGroupConversation(chatOwnerNameAlias, userToRemove, chatName);
    }

    @When("^User (\\w+) changes? name to (.*)$")
    public void IChangeName(String userNameAlias, String newName) {
        getCommonSteps().userChangesName(userNameAlias, newName);
    }

    @When("^User (\\w+) changes? accent color to (.*)$")
    public void IChangeAccentColor(String userNameAlias, String newColor) {
        getCommonSteps().userChangesAccentColor(userNameAlias, newColor);
    }

    @Given("^There (?:is|are) personal account users? (.*)")
    public void ThereAreUsers(String nameAliases) {
        final List<String> userNames = getCommonSteps().thereArePersonalUsers(nameAliases).stream()
                .map(ClientUser::getName)
                .collect(Collectors.toList());
        getCommonSteps().usersSetUniqueUsername(String.join(",", userNames));
        userNames.forEach(x -> {
            try {
                getCommonSteps().userChangesUserAvatarPicture(x);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
    }

    @Then("^I verify user's (.*) email on the backend is equal to (.*)")
    public void IVerifyEmailOnBackend(String user, String expectedValue) {
        getCommonSteps().userVerifiesEmail(user, expectedValue);
    }

    @Given("^User (.*) removes users? (.*) from team (.*)")
    public void UserXRemovesUsersFromTeam(String userNameAlias, String userAliases, String teamName) {
        getCommonSteps().userXRemovesUsersFromTeam(userNameAlias, userAliases, teamName);
    }

    @Given("^User (.*) has conversation (.*) with (.*) in team (.*)")
    public void UserHasGroupChatWithContacts(String chatOwnerNameAlias,
                                             String chatName, String otherParticipantsNameAliases, String teamName) {
        getCommonSteps().userHasGroupConversationInTeam(chatOwnerNameAlias, chatName, otherParticipantsNameAliases, teamName);
    }

    @Given("^User (.*) has 1:1 conversation with (.*) in team (.*)")
    public void UserHas1to1ChatInTeam(String chatOwnerNameAlias, String otherParticipantAlias, String teamName) {
        getCommonSteps().userHasGroupConversationInTeam(chatOwnerNameAlias, null, otherParticipantAlias, teamName);
    }


    @Given("^There is a team owner \"(.*)\" with team \"(.*)\"( without unique username)?$")
    public void thereIsATeamOwner(String userAlias, String teamName, String hasNoUniqueUsername) {
        if (hasNoUniqueUsername == null) {
            context.getCommonSteps().thereIsATeamOwner(userAlias, teamName, true);
        } else {
            context.getCommonSteps().thereIsATeamOwner(userAlias, teamName, false);
        }
    }

    @Given("^There is a team owner \"(.*)\" who sets up team \"(.*)\" for E2EI on (.*) backend")
    public void thereIsATeamOwnerWhoSetsUpTeamForE2EIOnBackend(String userAlias, String teamName, String backend) {
        thereIsATeamOwnerOnCustomBackend(userAlias, teamName, backend);
        getCommonSteps().userAddsKeycloakUserForE2EI(userAlias, userAlias);
        context.getCommonSteps().configureMLSForBund(userAlias, teamName);
        context.getCommonSteps().enableE2EIFeatureTeam(userAlias, teamName);
    }

    @Given("^There is a team owner \"(.*)\" with team \"(.*)\" on (.*) backend$")
    public void thereIsATeamOwnerOnCustomBackend(String userAlias, String teamName, String backendName) {
        Backend backend = BackendConnections.get(backendName);
        context.getCommonSteps().thereIsATeamOwner(userAlias, teamName, backend);
    }

    /**
     * Adds users to a team by creating them on the backend. Team owner user should already exist
     *
     * @param ownerNameAlias  team owner name/alias
     * @param userNameAliases team members aliases
     * @param teamName        the name of the team
     * @param role            one of available team roles
     */
    @Given("^User (.*) adds users? (.*) to team (.*) with role (Owner|Admin|Member|Partner)( and without unique usernames?)?$")
    public void UserXAddsUsersToTeam(String ownerNameAlias, String userNameAliases, String teamName, String role,
                                     String hasNoHandle) {
        boolean hasHandle = hasNoHandle == null;
        getCommonSteps().userXAddsUsersToTeam(ownerNameAlias, userNameAliases, teamName, role, hasHandle);
    }

    /**
     * Creates team owner user with one SSO team for Okta
     *
     * @param userAlias team owner name/alias
     * @param teamName  the name of the team to be created
     */
    @Given("^There is a team owner \"(.*)\" with SSO team \"(.*)\" configured for okta$")
    public void ThereIsASSOTeamOwnerForOkta(String userAlias, String teamName) {
        getCommonSteps().thereIsASSOTeamOwnerForOkta(userAlias, teamName);
    }

    @Given("^User (.*) adds users? (.*) to keycloak for E2EI$")
    public void userAddsKeycloakUserForE2EI(String ownerNameAlias, String userNameAliases) {
        getCommonSteps().userAddsKeycloakUserForE2EI(ownerNameAlias, userNameAliases);
    }

    @When("^Admin user (.*) enables E2EI with ACME server for team \"(.*)\"$")
    public void enableE2EIForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().enableE2EIFeatureTeam(adminUserAlias, teamName);
    }

    @When("^Admin user (.*) enables E2EI with insecure ACME server for team \"(.*)\"$")
    public void enableE2EIForTeamWithInsecureACME(String adminUserAlias, String teamName) {
        context.getCommonSteps().enableE2EIFeatureTeamWithInsecureACME(adminUserAlias, teamName);
    }

    @Given("^User (.*) adds users? (.*) to okta$")
    public void userAddsOktaUsers(String ownerNameAlias, String userNameAliases) {
        getCommonSteps().userAddsOktaUser(ownerNameAlias, userNameAliases);
    }

    @Given("^User (.*) adds users? (.*) to okta and SCIM$")
    public void userAddsUserToOktaAndSCIM(String ownerNameAlias, String userNameAliases) {
        getCommonSteps().userAddsUserToOktaAndSCIM(ownerNameAlias, userNameAliases);
    }

    @Given("^Team user (.*) invites wireless user (\\w+)(, which expires in \\d+ seconds?,)? to conversation (.*)$")
    public void userInvitesWirelessUsers(String ownerNameAlias, String userNameAliases, String timeoutSeconds,
                                         String conversationName) {
        if (timeoutSeconds == null) {
            getCommonSteps().userInvitesWirelessUsers(ownerNameAlias, userNameAliases, conversationName);
        } else {
            getCommonSteps().userInvitesWirelessUsers(ownerNameAlias, userNameAliases,
                    Duration.ofSeconds(Integer.parseInt(timeoutSeconds.replaceAll("\\D", ""))),
                    conversationName);
        }
    }

    @Given("Team user (.*) allows guests in conversation (.*)$")
    public void userInvitesWirelessUsers(String userNameAlias, String conversationName) {
        getCommonSteps().userAllowsGuestsInConversation(userNameAlias, conversationName);
    }

    @Given("^User (.*) creates invite link for conversation (.*)")
    public void userCreatesInviteLink(String userNameAlias, String conversationName) {
        getCommonSteps().userCreatesInviteLink(userNameAlias, conversationName);
    }

    /*
     * Creates a user with custom credentials. Useful to test with users we know exist (e.g.
     * the user who is connected to 255 people)
     */
    @Given("^There is a known user (.*) with email (.*) and password (.*)$")
    public void ThereIsAKnownUser(String name, String email, String password) {
        getCommonSteps().thereIsAKnownUser(name, email, password, BackendConnections.getDefault());
    }

    @Given("^User (.*) (en|dis)ables (.*) services? for team (.*)$")
    public void userWhitelistsService(String ownerOrAdminAlias, String action, String commaSeparatedServiceAliases,
                                      String teamName) {
        context.getCommonSteps().userSwitchesUsersServicesForTeam(ownerOrAdminAlias,
                action.equals("en"), commaSeparatedServiceAliases, teamName);
    }

    @When("^User (.*) (mutes|unmutes|allows only mentions for) conversation (.*)")
    public void muteConversationWithUser(String userToNameAlias, String action, String dstConvo) {
        switch (action) {
            case "mutes":
                getCommonSteps().userSetsMuteStatusForConversation(userToNameAlias, dstConvo, MuteState.MUTE_ALL);
                break;
            case "unmutes":
                getCommonSteps().userSetsMuteStatusForConversation(userToNameAlias, dstConvo, MuteState.NONE);
                break;
            case "allows only mentions for":
                getCommonSteps().userSetsMuteStatusForConversation(userToNameAlias, dstConvo, MuteState.MENTIONS_ONLY);
                break;
            default:
                throw new IllegalArgumentException(String.format("Unknown action: %s", action));
        }
    }

    @When("^User (.*) archives conversation (.*)")
    public void archiveConversationWithUser(String userToNameAlias, String dstConvoName) {
        getCommonSteps().userSetsArchivedStateForConversation(userToNameAlias, dstConvoName, true);
    }

    @When("^User (.*) (?:adds|updates) rich profile field \"(.*)\" with value \"(.*)\"$")
    public void userUpdatesEnrichedProfileViaSCIM(String userNameAlias, String key, String value) {
        getCommonSteps().userUpdatesRichProfile(userNameAlias, key, value);
    }

    @When("^User (.*) changes users? (.*) to role (.*) for conversation \"(.*)\"$")
    public void userChangesRoleOtherInConversation(String userName, String subjectUsers, String conversationRole, String conversationName) {
        getCommonSteps().userChangesRoleOtherInConversation(userName, subjectUsers, conversationRole, conversationName);
    }

    // region foma

    /*
     * The following 3 Methods can be used during the setup of a test when working with FOMA environment
     * These methods will check for 60 seconds if the needed pods are available and if we can start the testcase.
     */
    @Given("^I wait until the (federator|brig|galley) pod on (.*) is available$")
    public void waitUntilPodIsAvailable(String service, String backendName) throws Exception {
        context.getCommonSteps().waitUntilPodIsAvailable(backendName, service);
    }

    /*
     * This Method will turn the Federator for Federated environments on or off.
     * Turning the federator off will disable federation for the selected environment.
     */
    @Given("^Federator for backend (.*) is turned (on|off)$")
    public void turnFederatorforFederatedEnvironmentOnOrOff(String backendName, String status) throws Exception {
        if (status.equals("on")) {
            context.getCommonSteps().turnFederatorInBackendOn(backendName);
            context.getCommonSteps().checkPodsStatusOn(backendName, "federator");
        } else {
            context.getCommonSteps().turnFederatorInBackendOff(backendName);
            context.getCommonSteps().checkPodsStatusOff(backendName, "federator");
        }
    }

    @Then("^The search policy is (.*) with no team level restriction from (.*) backend to (.*) backend$")
    public void searchPolicyCheck(String searchPolicy, String fromBackend, String toBackend) {
        String toDomain = BackendConnections.get(toBackend).getDomain();
        assertThat("Search policy is not correct",
                context.getCommonSteps().getSearchPolicy(fromBackend),
                containsString("\"domain\":\"" + toDomain + "\","
                        + "\"restriction\":{\"tag\":\"allow_all\",\"value\":null},"
                        + "\"search_policy\":\"" + searchPolicy + "\""));
    }

    // endregion foma

    @Given("^User (.*) changes their email to (.*)$")
    public void userXchangesEmailToNewEmail(String userNameAliases, String email) {
        getCommonSteps().userChangesEmail(userNameAliases, email);
    }

    @Given("^TeamOwner \"(.*)\" waits and enables conference calling feature for team (.*) via backdoor$")
    public void TeamOwnerWaitsEnablesConferenceCallingViaBackdoor(String alias, String teamName) {
        // Wait until stripe/ibis has set free account restrictions after team creation.
        // This wait can be skipped if the driver was created because the creation usually
        // takes more than 3 seconds and is happening before a call is started.
        if (!context.isDriverCreated()) {
            Timedelta.ofSeconds(10).sleep();
        }
        context.getCommonSteps().enableConferenceCallingFeatureViaBackdoorTeam(alias, teamName);
    }

    @Given("^TeamOwner \"(.*)\" enables conference calling feature for team (.*) via backdoor$")
    public void TeamOwnerEnablesConferenceCallingViaBackdoor(String alias, String teamName) {
        context.getCommonSteps().enableConferenceCallingFeatureViaBackdoorTeam(alias, teamName);
    }

    @Given("^Personal Users (.*) enables conference calling feature via backdoor$")
    public void PersonalUserEnablesConferenceCalling(String alias) {
        context.getCommonSteps().enableConferenceCallingFeatureViaBackdoorPersonalUser(alias);
    }

    @Given("^TeamOwner \"(.*)\" sets the search behaviour for SearchVisibilityInbound to SearchableByOwnTeam for team (.*)$")
    public void TeamOwnerDisablesSearchInbound(String alias, String teamName) {
        //SearchableByOwnTeam = disabled
        context.getCommonSteps().disableSearchVisibilityInbound(alias, teamName);
    }

    @Given("^TeamOwner \"(.*)\" enables the search behaviour for TeamSearchVisibility for team (.*)$")
    public void TeamOwnerEnablesSearchOutbound(String alias, String teamName) {
        context.getCommonSteps().enableTeamSearchVisibilityOutbound(alias, teamName);
    }

    @Given("^TeamOwner \"(.*)\" sets the search behaviour for TeamSearchVisibility to SearchVisibilityNoNameOutsideTeam for team (.*)$")
    public void TeamOwnerSetsSearchOutboundSearchVisibilityNoNameOutsideTeam(String alias, String teamName) {
        context.getCommonSteps().setTeamSearchVisibilityOutboundNoNameOutsideTeam(alias, teamName);
    }

    @When("^Admin user (.*) enables 2 Factor Authentication for team (.*)$")
    public void userOwnerEnablesGuestLinksForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().enable2FAuthentication(adminUserAlias, teamName);
    }

    @When("^Admin user (.*) disables 2 Factor Authentication for team (.*)$")
    public void userOwnerDisablesGuestLinksForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().disable2FAuthentication(adminUserAlias, teamName);
    }

    @When("^Admin user (.*) unlocks 2F Authentication for team (.*)$")
    public void userOwnerUnlocks2FAuthenticationForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().unlock2FAuthentication(adminUserAlias, teamName);
    }

    @Given("^User (.*) configures MLS for team \"(.*)\"$")
    public void enableMLSForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().configureMLSForBund(adminUserAlias, teamName);
    }

    @When("^Admin user (.*) disables MLS for team (.*) via backdoor$")
    public void disableMLSForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().disableMLSFeatureTeam(adminUserAlias, teamName);
    }

    @Given("^User (.*) has MLS conversation \"(.*)\" with (.*)$")
    public void userHasMLSGroupChat(String chatOwnerNameAlias, String chatName, String participantAliases) {
        context.getCommonSteps().userHasMLSGroupConversation(chatOwnerNameAlias, chatName, participantAliases);
    }

    @When("^User (.*) adds (\\d+) devices?$")
    public void userAddsDevices(String userNameAlias, int amount) {
        for (int i = 1; i <= amount; i++) {
            context.getCommonSteps().addDevice(userNameAlias, null,
                    "Device" + i, Optional.of("Label" + i), true);
        }
    }

    @Given("^There is a known user (.*) with email (.*) and password (.*) on (.*) backend$")
    public void ThereIsAKnownUserOnBackend(String name, String email, String password, String backend) {
        getCommonSteps().thereIsAKnownUser(name, email, password, BackendConnections.get(backend));
    }

    private static List<String> extractEmails(String emails) {
        return Arrays.stream(emails.split(","))
                .map(String::trim)
                .collect(Collectors.toList());
    }

    @Then("^User (.*) send invitations? to emails (.*) to join the (.*) team as a member$")
    public void ISendTeamInvites(String ownerAlias, String emails, String dstTeam) {
        for (String email : extractEmails(emails)) {
            context.getCommonSteps().userXSendsInvitationMailToMember(ownerAlias, email, dstTeam, "member");
        }
    }
    @Then("^I print all created users in the execution log$")
    public void IPrintAllCreatedUsers() {
        context.getCommonSteps().printAllCreatedUsers();
    }


    @When("^Admin of (.*) backend revokes remembered certificate on ACME server$")
    public void revokeRememberedCertificate(String backendName) throws CertificateException {
        String pem = context.getRememberedCertificate();
        byte [] decoded = Base64.getDecoder().decode(pem
            .replaceAll("-----BEGIN CERTIFICATE-----", "")
            .replaceAll("-----END CERTIFICATE-----", "")
            .replaceAll("\n", "")
            .replaceAll(" ", "")
            .strip());

        CertificateFactory factory = CertificateFactory.getInstance("X.509");
        X509Certificate certificate = (X509Certificate) factory.generateCertificate(new ByteArrayInputStream(decoded));
        String serialNumber = "0x" + certificate.getSerialNumber().toString(16);
        context.getCommonSteps().revokeCertificate(backendName, serialNumber, certificate.getSerialNumber());
    }

    @When("^Users? (.*) claims? key packages$")
    public void claimKeyPackages(String userAliases) {
        context.getCommonSteps().claimKeyPackages(userAliases);
    }
}
