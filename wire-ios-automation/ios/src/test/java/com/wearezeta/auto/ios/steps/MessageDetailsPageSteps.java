package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.MessageDetailsPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class MessageDetailsPageSteps {
    IOSTestContext context;

    public MessageDetailsPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private MessageDetailsPage getMessageDetailsPage() {
        return context.getPagesCollection().getPage(MessageDetailsPage.class);
    }

    @When("^I close the message details$")
    public void ICloseTheMessageDetails() {
        getMessageDetailsPage().tapCloseButton();
    }

    @Then("^I see user (.*) in the Seen list$")
    public void ISeeUserInMessageDetailSeenPage(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
            assertThat(String.format("User name '%s' is not visible in Message Detail Seen list", name),
                    getMessageDetailsPage().isContactVisibleInSeenTab(name));
    }
}