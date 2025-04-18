package com.wearezeta.auto.ios.steps.conversation_details.single;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.pages.details_overlay.single.SinglePendingUserIncomingConnectionProfilePage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class SinglePendingUserIncomingConnectionProfilePageSteps {
    IOSTestContext context;

    public SinglePendingUserIncomingConnectionProfilePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SinglePendingUserIncomingConnectionProfilePage getPage()  {
        return context.getPagesCollection()
                .getPage(SinglePendingUserIncomingConnectionProfilePage.class);
    }

    @Then("^I (do not )?see name \"(.*)\" on Single user Pending incoming connection profile page$")
    public void ISeeDisplayName(String shouldNotSee, String value)  {
        value = context.getUsersManager().replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat("Username is expected to be visible",getPage().isDisplayNameVisible(value));
        } else {
            assertThat("Username is expected to be invisible",getPage().isDisplayNameInvisible(value));
        }
    }

    @When("^I tap Connect inbox-style button on Single user Pending incoming connection profile page$")
    public void ITapConnectInboxStyleButton()  {
        getPage().tapConnect();
    }

    @When("^I tap Ignore inbox-style button on Single user Pending incoming connection profile page$")
    public void ITapIgnoreInboxStyleButton()  {
        getPage().tapIgnoreInboxStyleButton();
    }

    @When("^I tap Back button on Single user Pending incoming connection profile page$")
    public void ITapBackButton()  {
        getPage().tapBackButton();
    }
}
