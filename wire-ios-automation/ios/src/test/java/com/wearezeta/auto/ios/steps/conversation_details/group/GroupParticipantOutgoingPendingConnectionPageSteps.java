package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupPendingParticipantOutgoingConnectionPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class GroupParticipantOutgoingPendingConnectionPageSteps {
    IOSTestContext context;

    public GroupParticipantOutgoingPendingConnectionPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GroupPendingParticipantOutgoingConnectionPage getPage()  {
        return context.getPagesCollection()
                .getPage(GroupPendingParticipantOutgoingConnectionPage.class);
    }

    @Then("^I see name \"(.*)\" on Group participant Pending outgoing connection page$")
    public void ISeeLabel(String value)  {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
                assertThat(String.format("name '%s' is expected to be visible", value),
                        getPage().isUserNameVisible(value));
    }

    @Then("^I see Connect button on Group participant Pending outgoing connection page$")
    public void ISeeConnectButton()  {
            assertThat("'Connect' button is expected to be visible",
                    getPage().isConnectButtonVisible());
    }

    @When("^I tap Open Menu button on Group participant Pending outgoing connection page$")
    public void ITapOpenMenuButton() {
        getPage().tapOpenMenuButton();
    }
}
