package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Given;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.pages.SearchUIPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.not;

public class SearchUIPageSteps {
    IOSTestContext context;

    public SearchUIPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SearchUIPage getSearchUIPage() {
        return context.getPagesCollection()
                .getPage(SearchUIPage.class);
    }

    /**
     * Type in text in Search input field
     *
     * @param text                   text to input
     * @param isUpper                null if should be input as it is
     * @param shouldClearBeforeInput equals to null if the field should not be cleared first
     */
    @When("^I type \"(.*)\" in (cleared )?Search UI input field( in upper case)?$")
    public void ITypeInSearchInput(String text, String shouldClearBeforeInput, String isUpper) {
        text = context.getUsersManager()
                .replaceAliasesOccurrences(text, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.EMAIL_ALIAS, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        getSearchUIPage().typeSearchQuery((isUpper == null) ? text : text.toUpperCase(),
                shouldClearBeforeInput != null);
    }

    @When("^I search user (.*) by email in Search UI input field$")
    public void iSearchByEmail(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        getSearchUIPage().typeSearchQuery(user.getEmail(), false);
    }

    @When("^I search user (.*) by handle and domain in Search UI input field$")
    public void iSearchByHandleAndDomain(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        String domain = BackendConnections.get(user).getDomain();
        getSearchUIPage().typeSearchQuery(user.getUniqueUsername() + "@" + domain, false);
    }

    @When("^I clear Search UI input field$")
    public void iClearSearchInput() {
        getSearchUIPage().clearSearchInput();
    }

    @When("^I enter unique username with backend domain of user (.*) in (cleared )?Search UI input field$")
    public void ITypeUniqueUsernameAndDomainOfUser(String userAlias, String shouldClearBeforeInput) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        String backendName = BackendConnections.get(user).getDomain();

        getSearchUIPage().typeSearchQuery(String.format("%s@%s", user.getUniqueUsername(), backendName), shouldClearBeforeInput != null);
    }

    /**
     * Fills in search field pointed amount of letters from username/conversation starting from the first one
     *
     * @param count           amount of letters to be input
     * @param name            user name
     * @param shouldBeCleared equals to null oif the input field should not be cleaned before input
     */
    @When("^I type first (\\d+) letters? of (?:user|conversation) name \"(.*)\" into (cleared )?Search UI input field$")
    public void ITypeXLettersIntoSearchInput(int count, String name, String shouldBeCleared) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        if (name.length() > count) {
            getSearchUIPage().typeSearchQuery(name.substring(0, count), shouldBeCleared != null);
        } else {
            throw new IllegalArgumentException(String.format("Name is only %s chars length. Put in step a less value",
                    name.length()));
        }
    }

    /**
     * Verify that conversation or service is presented in search results
     *
     * @param name           conversation or service name to search
     * @param shouldNotExist equals to null if the conversation should be visible
     * @param times          defines count of entities in search result if set
     */
    @When("^I see the (?:conversation|service) \"(.*)\" (does not )?exists? (\\d+ times? )?in Search results$")
    public void ISeeConversationIsFoundInSearchResult(String name, String shouldNotExist,
                                                      String times) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        int expectedCount = 1;
        if (times != null) {
            expectedCount = Integer.parseInt(times.replaceAll("[\\D]", ""));
        }
        if (expectedCount == 1) {
            if (shouldNotExist == null) {
                assertThat(String.format("The conversation '%s' does not exist in Search results", name),
                        getSearchUIPage().isElementFoundInSearch(name));
            } else {
                assertThat(
                        String.format("The conversation '%s' exists in Search results, but it should not", name),
                        getSearchUIPage().isElementNotFoundInSearch(name));
            }
        } else {
            final int actualCount = getSearchUIPage().getOccurrencesCount(name);
            if (shouldNotExist == null) {
                assertThat(String.format("The conversation '%s' should occur %d times in Search result",
                        name, expectedCount), actualCount, equalTo(expectedCount));
            } else {
                assertThat(String.format("The conversation '%s' should not occur %d times in Search result",
                        name, expectedCount), actualCount, not(equalTo(expectedCount)));
            }
        }
    }

    /**
     * (Un)Select pointed amount of avatars from top people in a row starting from the first one
     *
     * @param count amount of avatars that should be (un)selected
     */
    @Then("^I (?:unselect|select) (\\d+) avatars? from Top connections$")
    public void ISelectTopConnectionAvatars(int count) {
        getSearchUIPage().tapTopConnectionsAvatars(count);
    }

    /**
     * Tap on top connection contact avatar by pointed id order
     *
     * @param position contact position in top people. Starts from 1
     */
    @When("^I tap the (\\d+)\\w+ avatar in Top connections$")
    public void IClickOnTopConnectionByOrder(int position) {
        getSearchUIPage().tapOnTopConnectionAvatarByOrder(position);
    }

    /**
     * Click on conversation or service in search result with pointed name
     *
     * @param name conversation or service name
     */
    @When("^I tap on (?:conversation|service) (.*) in search result$")
    public void ITapOnConversationFromSearch(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getSearchUIPage().selectElementInSearchResults(name);
    }

    @When("^I tap Create Group button on Search UI page$")
    public void ITapCreateGroupButton() {
        getSearchUIPage().tapCreateGroupButton();
    }

    @When("^I tap X button on Search UI page$")
    public void ITapCloseButton() {
        getSearchUIPage().tapCloseButton();
    }

    @When("^I tap Send Invite button on Search UI page$")
    public void ITapSendInviteButton() {
        getSearchUIPage().tapSendInviteButton();
    }

    @When("^I tap Copy Invite button on Search UI page$")
    public void ITapCopyInviteButton() {
        getSearchUIPage().tapCopyInviteButton();
    }

    @Then("^I (do not )?see Create Group button on Search UI page$")
    public void ISeeCreateGroupButton(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The button Create Group is expected to be visible",
                    getSearchUIPage().isCreateGroupButtonVisible());
        } else {
            assertThat("The button Create Group is expected to be invisible",
                    getSearchUIPage().isCreateGroupButtonInvisible());
        }
    }

    @Then("^I (do not )?see Create Guest Room button on Search UI page$")
    public void ISeeCreateGuestRoomButton(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The button Create Guest Room is expected to be visible",
                    getSearchUIPage().isCreateGuestRoomButtonVisible());
        } else {
            assertThat("The button Create Guest Room is expected to be invisible",
                    getSearchUIPage().isCreateGuestRoomButtonInvisible());
        }
    }

    /**
     * Presses the instant connect plus button
     *
     * @param nameAlias user name/aias
     */
    @When("^I tap the instant connect button next to (.*)")
    public void ITapInstantConnectButton(String nameAlias) {
        nameAlias = context.getUsersManager()
                .replaceAliasesOccurrences(nameAlias, ClientUsersManager.FindBy.NAME_ALIAS);
        getSearchUIPage().tapInstantConnectButton(nameAlias);
    }

    @Given("^I (do not )?see the service \"([^\"]*)\" exists in service search results$")
    public void iSeeTheServiceExistsInServiceSearchResults(String shouldNotSee, String serviceName) {
        if (shouldNotSee == null) {
            assertThat("Service " + serviceName + " does not exist in search result.",
                    getSearchUIPage().isServiceVisibleInSearchResult(serviceName));
        } else {
            assertThat("Service \" + serviceName + \" exist in search result but it should not.",
                    getSearchUIPage().isServiceInVisibleInSearchResult(serviceName));
        }
    }

    @Given("^I tap on service \"([^\"]*)\" in service search result$")
    public void iTapOnServiceServiceNameInServiceSearchResult(String serviceName) {
        getSearchUIPage().tapOnService(serviceName);
    }

    @Then ("^I open create group screen$")
    public void iOpenCreateGroupScreen() {
        getSearchUIPage().iOpenCreateGroupScreen();
    }
    @Then("^I (do not )?see contact (.*) in Search UI$")
    public void iSeeContactInSearchUI(String shouldNotSee, String name) {
         name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("The contact '%s' is not visible", name), getSearchUIPage().isContactVisible(name));
        } else {
            assertThat(String.format("The contact '%s' is visible while it should not be", name), getSearchUIPage().isContactInvisible(name));
        }
    }
}
