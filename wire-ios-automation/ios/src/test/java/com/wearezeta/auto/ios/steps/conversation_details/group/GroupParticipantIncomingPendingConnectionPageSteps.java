package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupPendingParticipantIncomingConnectionPage;
import io.cucumber.java.en.Then;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;

public class GroupParticipantIncomingPendingConnectionPageSteps {
    IOSTestContext context;

    public GroupParticipantIncomingPendingConnectionPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GroupPendingParticipantIncomingConnectionPage getGroupParticipantIncomingConnectionPage()  {
        return context.getPagesCollection()
                .getPage(GroupPendingParticipantIncomingConnectionPage.class);
    }

    @Then("^I see name \"(.*)\" on Group participant Pending incoming connection page$")
    public void iSeeNameOnGroupParticipantPendingIncomingConnectionPage(String value)  {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
                assertThat(String.format("name '%s' is expected to be visible", value),
                        getGroupParticipantIncomingConnectionPage().isUserDetailNameVisible(value));
    }
}
