package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ForwardPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class ForwardPageSteps {
    IOSTestContext context;

    public ForwardPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ForwardPage getPage()  {
        return context.getPagesCollection().getPage(ForwardPage.class);
    }

    @When("^I tap Send button on Forward page$")
    public void ITapSendButton()  {
        getPage().tapSendButton();
    }

    /**
     * Select the corresponding conversation from the list on Forward page
     *
     * @param name conversation name/alias
     */
    @Then("^I select (.*) conversation on Forward page$")
    public void ISelectConversation(String name)  {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getPage().selectConversation(name);
    }

    /**
     * Verify whether a conversation is visible in the list of conversations available
     * for message forwarding
     *
     * @param shouldNotSee equals to null if the conversation should be visible
     * @param name         conversation name/alias
     */
    @When("^I (do not )?see (.*) conversation on Forward page$")
    public void ISeeConversation(String shouldNotSee, String name)  {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("The '%s' conversation is expected to be visible", name),
                    getPage().isConversationVisible(name));
        } else {
            assertThat(String.format("The '%s' conversation is expected to be invisible", name),
                    getPage().isConversationInvisible(name));
        }
    }

    /**
     * Verify whether a conversation with legal hold has the legal hold indicator on the message forward page
     *
     * @param shouldNotSee equals to null if the legal hold indicator should be visible
     */
    @When("^I (do not )?see (legal hold indicator|shield icon|guest icon|external icon) on Forward page$")
    public void ISeeIconOnForwardPage(String shouldNotSee, String icon)  {
        if (shouldNotSee == null) {
            if(icon.equals("shield icon")) {
               // check if shield icon is visible
                assertThat("Shield icon is not visible", getPage().isShieldIconVisible());
            } else if (icon.equals("guest icon")) {
                // check if guest icon is visible
                assertThat("Guest icon is not visible", getPage().isGuestIconVisible());
            } else if (icon.equals("external icon")) {
                // check if guest icon is visible
                assertThat("external icon is not visible", getPage().isExternalIconVisible());
            } else {
                //check if legal hold indicator is visible
                assertThat("Legal Hold indicator icon is not visible", getPage().isLegalHoldIndicatorVisible());
            }
        } else {
            // Should not be visible
            if (icon.equals("shield icon")) {
                // check if shield icon is not visible
                assertThat("Shield icon is visible while it should not be", getPage().isShieldIconInvisible());
            } else if (icon.equals("guest icon")) {
                // check if guest icon is not visible
                assertThat("Guest icon is visible while it should not be", getPage().isGuestIconInvisible());
            } else if (icon.equals("external icon")) {
                // check if external icon is not visible
                assertThat("external icon is visible while it should not be", getPage().isExternalIconInvisible());
            } else {
                // check if Legal hold indicator is not visible
                assertThat("Legal hold indicator is visible while it should not be", getPage().isLegalHoldIndicatorInvisible());
            }
        }
    }
}
