package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupPeoplePage;
import io.cucumber.java.en.Then;
import static org.hamcrest.MatcherAssert.assertThat;

public class GroupPeoplePageSteps {
    IOSTestContext context;

    public GroupPeoplePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GroupPeoplePage getPage() {
        return context.getPagesCollection().getPage(GroupPeoplePage.class);
    }

    @Then("^I see external indicator for user (.*) on People page$")
    public void iSeeExternalIndicatorFor(String userName) {
        userName = context.getUsersManager().replaceAliasesOccurrences(userName, ClientUsersManager.FindBy.NAME_ALIAS);
            assertThat(String.format("External Indicator is not visible for user %s", userName), getPage().isExternalIndicatorVisibleFor(userName));
    }

    @Then("^I tap on user (.*) on People page$")
    public void iTapOnUser(String userName) {
        userName = context.getUsersManager().replaceAliasesOccurrences(userName, ClientUsersManager.FindBy.NAME_ALIAS);
        getPage().selectParticipantPeoplePage(userName);
    }

    @Then("^I (do not )?see Members section header on People page$")
    public void iSeeSectionHeaderMembers(String doNot) {
        if (doNot == null) {
            assertThat("Members section is not visible on people page while it should be", getPage().isMembersSectionVisible());
        } else {
            assertThat("Members section is visible on people page while it should not be", getPage().isMembersSectionInvisible());
        }
    }

    @Then("^I (do not )?see Admins section header on People page$")
    public void iSeeSectionHeaderAdmins(String doNot) {
        if (doNot == null) {
            assertThat("Admins section is not visible on people page while it should be", getPage().isAdminsSectionVisible());
        } else {
            assertThat("Admins section is visible on people page while it should not be", getPage().isAdminsSectionInvisible());
        }
    }

    @Then("^I (do not )?see user (.*) in the Admins section on People page$")
    public void iSeeUserInAdminSection(String doNot, String userName) {
        userName = context.getUsersManager().replaceAliasesOccurrences(userName, ClientUsersManager.FindBy.NAME_ALIAS);
        if (doNot == null) {
            assertThat("User %s is not visible in the admin section on People page while it should be", getPage().isUserInAdminsSection(userName));
        } else {
            assertThat("User %s is visible in the admin section on People page while it should not be", getPage().isUserNotInAdminsSection(userName));
        }
    }
}
