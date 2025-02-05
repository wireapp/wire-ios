package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupConnectedParticipantProfilePage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class GroupParticipantConnectedProfilePageSteps {
    IOSTestContext context;

    public GroupParticipantConnectedProfilePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GroupConnectedParticipantProfilePage getPage() {
        return context.getPagesCollection().getPage(GroupConnectedParticipantProfilePage.class);
    }

    @When("^I tap Remove From Conversation button on Group participant profile page$")
    public void ITapRemoveButton() {
        getPage().tapRemoveFromConversationButton();
    }

    @When("I confirm removal from group")
    public void ConfirmRemoval() {
        getPage().confirmRemove();
    }

    @When("^I tap Open Conversation button on Group participant profile page$")
    public void ITapOpenConversationButton() {
        getPage().tapOpenConversationButton();
    }

    @When("^I tap Back button on Group participant profile page$")
    public void ITapBackButton() {
        getPage().tapBackButton();
    }

    @When("^I tap Open Menu button on Group participant profile page$")
    public void ITapOpenMenuButton() {
        getPage().tapOpenMenuButton();
    }

    @When("^I see name \"(.*)\" on Group participant profile page$")
    public void ISeeLabel(String value) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        assertThat(String.format("'%s' field is expected to be visible", value),
                        getPage().isUserDetailNameVisible(value));
    }

    @When("^I do not see name on Group participant profile page$")
    public void IDoNotSeeName() {
                assertThat("'name' field is expected to be invisible",
                        getPage().isUserDetailNameInvisible());
    }

    @When("^I switch to Devices tab on Group participant profile page$")
    public void IChangeTabToDevices() {
        getPage().tapDevicesTab();
    }

    @Then("^I (do not )?see Open Conversation button on Group participant profile page$")
    public void ISeeOpenConversationButtonOnGroupInfoPage(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Open conversation button should be visible",
                    getPage().isOpenConversationButtonVisible());
        } else {
            assertThat("Open conversation should not be visible",
                    getPage().isOpenConversationInvisible());
        }
    }

    @Then("^I (do not )?see More Actions button on Group participant profile page$")
    public void ISeeMoreActionsButton(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The More Actions button is not visible on Single user profile page",
                    getPage().isMoreActionsButtonVisible());
        } else {
            assertThat("The More Actions button is still visible on Single user profile page",
                    getPage().isMoreActionsButtonInvisible());
        }
    }

    @Then("^I (do not )?see Connect button on Group participant profile page$")
    public void ISeeConnectButtonOnGroupInfoPage(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Connect button should be visible",
                    getPage().isConnectButtonVisible());
        } else {
            assertThat("Connect button should not be visible",
                    getPage().isConnectButtonInvisible());
        }
    }

    @Then("^I do not see left action button on Group participant profile page$")
    public void IDoNotSeeLeftActionButtonOnGroupInfoPage() {
        assertThat("Left action button should not be visible",
                getPage().isLeftActionButtonInvisible());
    }

    @Then("^I (do not )?see Admin toggle on Group participant profile page$")
    public void iSeeAdminToggle(String doNot) {
        if (doNot == null) {
            assertThat("Admin toggle is not visible while it should be",
                    getPage().isAdminToggleVisible());
        } else {
            assertThat("Admin toggle is visible while it should not be",
                    getPage().isAdminToggleInvisible());
        }
    }

    @Then("^I tap Admin toggle on Group participant profile page$")
    public void iTapAdminToggle() {
        getPage().tapAdminToggle();
    }

    @Then("^I (do not )?see Admin icon on Group participant profile page$")
    public void iSeeAdminIcon(String doNot) {
        if (doNot == null) {
            assertThat("Admin icon is not visible while it should be",
                    getPage().isAdminIconVisible());
        } else {
            assertThat("Admin icon is visible while it should not be",
                    getPage().isAdminIconInvisible());
        }
    }

    @Then("^I (do not )?see External icon on Group participant profile page$")
    public void iSeeExternalIcon(String doNot) {
        if (doNot == null) {
            assertThat("External icon is not visible while it should be",
                    getPage().isExternalIconVisible());
        } else {
            assertThat("External icon is visible while it should not be",
                    getPage().isExternalIconInvisible());
        }
    }
}
