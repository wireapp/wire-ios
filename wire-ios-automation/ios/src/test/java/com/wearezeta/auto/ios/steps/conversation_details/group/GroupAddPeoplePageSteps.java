package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupAddPeoplePage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

import java.util.List;

public class GroupAddPeoplePageSteps {

    IOSTestContext context;

    public GroupAddPeoplePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GroupAddPeoplePage getPage() {
        return context.getPagesCollection().getPage(GroupAddPeoplePage.class);
    }

    @When("^I tap Add Participants button on Group Add People page$")
    public void iTapAddButton() {
        getPage().tapAddButton();
    }

    /**
     * Types the given string into the search field
     *
     * @param query search query text
     */
    @When("^I type search query \"(.*)\" on Group Add People page$")
    public void iTypeSearchQuery(String query) {
        query = context.getUsersManager()
                .replaceAliasesOccurrences(query, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.EMAIL_ALIAS, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        getPage().typeSearchQuery(query);
    }

    @When("^I type first (\\d+) letters? of name \"(.*)\" in search input field on Add People page$")
    public void ITypeFirstCharactersOfNameInSearchInputFieldOnAddPeoplePage(int count, String name)  {
        name = context.getUsersManager()
            .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        name = context.getUsersManager()
            .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);

        if (name.length() > count) {
            getPage().typeSearchQuery(name.substring(0, count));
        } else {
            throw new IllegalArgumentException(String.format("Name is only %s chars length. Put in step a less value",
                name.length()));
        }
    }

    /**
     * Select/unselect the coresposning search result item
     *
     * @param name the name of the search item
     */
    @When("^I (?:select|unselect) search result item (.*) on Group Add People page$")
    public void iSelectItem(String name) {
        name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getPage().selectItem(name);
    }

    /**
     * Verifies whether contacts are present on Group chat info page
     *
     * @param shouldNotSee equals to null if participants should be visible
     * @param contacts     one or more participant names/aliases
     */
    @Then("^I (do not )?see search result items? (.*) on Group Add People page$")
    public void ISeeContactInGroupInfo(String shouldNotSee, String contacts) {
        final List<String> aliases = context.getUsersManager().splitAliases(contacts);
        for (final String alias : aliases) {
            final String name = context.getUsersManager()
                    .replaceAliasesOccurrences(alias, ClientUsersManager.FindBy.NAME_ALIAS);
            if (shouldNotSee == null) {
                assertThat(String.format("User '%s' should be visible", name), getPage().isItemVisible(name));
            } else {
                assertThat(String.format("User '%s' should not be visible", name), getPage().isItemInvisible(name));
            }
        }
    }

    /**
     * Verify whether a label is visible in search results
     */
    @Then("^I see \"(No Results|Everyone is here)\" label on Group Add People page$")
    public void ISeeResultLabel(String msg) {
        assertThat(String.format("Label '%s' should be visible", msg),
                getPage().waitUntilResultsLabelIsVisible(msg));
    }
}

