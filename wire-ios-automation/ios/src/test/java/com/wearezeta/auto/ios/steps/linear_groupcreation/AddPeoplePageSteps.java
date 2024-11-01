package com.wearezeta.auto.ios.steps.linear_groupcreation;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.linear_groupcreation.AddPeoplePage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;

public class AddPeoplePageSteps {
    IOSTestContext context;

    public AddPeoplePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private AddPeoplePage getPage()  {
        return context.getPagesCollection().getPage(AddPeoplePage.class);
    }

    @When("^I tap Create button on Add People page$")
    public void ITapCreateButtonOnAddPeoplePage()  {
        getPage().tapCreateButton();
    }

    @When("^I tap Skip button on Add People page$")
    public void ITapSkipButtonOnAddPeoplePage()  {
        getPage().tapSkipButton();
    }

    @When("^I tap Back button on Add People page$")
    public void ITapBackButtonOnAddPeoplePage()  {
        getPage().tapBackButton();
    }

    @When("^I type \"(.*)\" in (cleared )?search input field on Add People page$")
    public void ITypeInSearchInputFieldOnAddPeoplePage(String userName, String shouldBeCleared)  {
        userName = context.getUsersManager()
                .replaceAliasesOccurrences(userName, ClientUsersManager.FindBy.NAME_ALIAS, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        getPage().typeSearchQuery(userName, shouldBeCleared != null);
    }

    @Then("^I see the count of selected participants is (\\d+) on Add People page$")
    public void ISeeParticipantCount(int expectedCount)  {
        assertThat(String.format("The count of participant is not %s", expectedCount),
                getPage().isParticipantsCountEqualTo(expectedCount));
    }

    @When("^I (?:select|unselect) search result item (.*) on Add People page$")
    public void iSelectItem(String name) {
        name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getPage().selectItem(name);
    }

    @Then("^I see \"(No Results|Everyone is here)\" label on Add People page$")
    public void ISeeResultLabel(String msg) {
        assertThat(String.format("Label '%s' should be visible", msg),
                getPage().waitUntilResultsLabelIsVisible(msg));
    }
}
