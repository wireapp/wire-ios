package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.IOSPage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupDetailsPage;
import io.cucumber.java.en.And;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.util.List;

public class GroupDetailsPageSteps {
    IOSTestContext context;

    public GroupDetailsPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GroupDetailsPage getGroupDetailsPage() {
        return context.getPagesCollection().getPage(GroupDetailsPage.class);
    }

    @When("^I change group conversation name to \"(.*)\" on Group Details page$")
    public void IChangeConversationNameTo(String name) {
        getGroupDetailsPage().setGroupChatName(name);
    }

    @When("^I tap Add People button on Group Details page$")
    public void ITapAddPeopleButton() {
        getGroupDetailsPage().tapAddPeopleButton();
    }
    
    @When("^I close Group Details$")
    public void ITapXButton() {
        getGroupDetailsPage().tapXButton();
    }

    @When("^I tap Open Menu button on Group Details page$")
    public void ITapOpenMenuButton() {
        getGroupDetailsPage().tapOpenMenuButton();
    }

    @Then("^I (do not )?see Add People button on Group Details page$")
    public void ItSeeAddPeopleButtonOnGroupInfoPage(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Button Add People should be visible",
                    getGroupDetailsPage().isAddPeopleButtonVisible());
        } else {
            assertThat("Button Add People should not be visible",
                    getGroupDetailsPage().isAddPeopleButtonInvisible());
        }
    }

    @When("^I try to change group conversation name to random with length (\\d+) on Group Details page$")
    public void IChangeConversationNameToRandom(int length) {
        String name = CommonUtils.generateRandomString(length);
        getGroupDetailsPage().setGroupChatName(name);
    }

    @Then("^I see conversation name \"(.*)\" on Group Details page$")
    public void ISeeCorrectConversationName(String expectedName) {
        assertThat(String.format("Group conversation name is not equal to '%s'", expectedName),
                getGroupDetailsPage().isGroupNameEqualTo(expectedName));
    }

    @Then("^I see Group Name is enabled on Group Details page$")
    public void ISeeConversationNameEnabled() {
            assertThat("Group conversation name is not enabled but it should be", getGroupDetailsPage().isGroupChatNameEnabled());
    }

    @When("^I select participant (.*) on Group Details page$")
    public void ISelectParticipant(String name) {
        name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
            getGroupDetailsPage().selectParticipant(name);
    }

    @Then("^I see (\\d+) Members label on Group Details page$")
    public void ISeeThatConversationHasNumberMemberParticipants(int number) {
        assertThat(String.format("The actual number of Members in the chat is not the same as expected number %s",
                number), getGroupDetailsPage().isNumberOfMembersParticipantsEquals(number));
    }

    @Then("^I see (\\d+) Admins label on Group Details page$")
    public void ISeeThatConversationHasNumberAdminParticipants(int number) {
        assertThat(String.format("The actual number of Admins in the chat is not the same as expected number %s",
              number), getGroupDetailsPage().isNumberOfAdminsParticipantsEquals(number));
    }

    @When("^I see (\\d+) (participants? avatars?|services?) on Group Details page$")
    public void ISeeNumberParticipantsAvatars(int expectedCount, String type) {
        assertThat(String.format("Actual number of items is not the same as expected (%s)", expectedCount),
                CommonUtils.waitUntilTrue(Timedelta.ofSeconds(10), Timedelta.ofMillis(1), () -> {
                    final int actual = type.startsWith("service")
                            ? getGroupDetailsPage().getServicesCount()
                            : getGroupDetailsPage().getParticipantsCount();
                    return actual == expectedCount;
                })
        );
    }

    @And("^I swipe up on Group Details page$")
    public void iSwipeUp() {
        getGroupDetailsPage().swipe(IOSPage.SwipeDirection.UP);
    }

    @Then("^I see the participant (.*) has External indicator on Group Details page$")
    public void ISeeExternalIndicator(String name) {
        name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        assertThat(String.format("The participant '%s' has no 'External Indicator'", name),
                getGroupDetailsPage().isExternalIndicatorVisibleFor(name));
    }

    @Then("^I (do not )?see participant names? (.*) on Group Details page$")
    public void ISeeContactInGroupInfo(String shouldNotSee, String contacts) {
        final List<String> aliases = context.getUsersManager().splitAliases(contacts);
        for (final String alias : aliases) {
            final String name = context.getUsersManager()
                    .replaceAliasesOccurrences(alias, ClientUsersManager.FindBy.NAME_ALIAS);
            if (shouldNotSee == null) {
                assertThat(String.format("User '%s' should be visible", name),
                        getGroupDetailsPage().isParticipantVisible(name));
            } else {
                assertThat(String.format("User '%s' should not be visible", name),
                        getGroupDetailsPage().isParticipantInvisible(name));
            }
        }
    }

    @Then("^I see the length of group conversation name equals to (\\d+) on Group Details page$")
    public void IVerifyNameLength(int expectedLength) {
        final int actualLength = getGroupDetailsPage().getGroupNameLength();
        assertThat(String.format("The actual group name length %d is not equal to the expected length %d",
                actualLength, expectedLength), actualLength, equalTo(expectedLength));
    }

    @When("^I tap Guest Options? on Group Details page$")
    public void iOpenGuestOptions() {
        getGroupDetailsPage().openGuestOptions();
    }

    /**
     * Verifies whether Guest Options is present on Group chat info page
     *
     * @param shouldNotSee equals to null if Guest Options should be visible
     */
    @Then("^I (do not )?see Guest Options on Group Details page$")
    public void ISeeGuestOptionsOnGroupInfo(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Guest Options should be visible",
                    getGroupDetailsPage().isGuestOptionsVisible());
        } else {
            assertThat("Guest Options should not be visible",
                    getGroupDetailsPage().isGuestOptionsInvisible());
        }
    }

    @Then("^I (do not )?see Services Options on Group Details page$")
    public void ISeeServicesOptionsOnGroupInfo(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Services Options should be visible",
                    getGroupDetailsPage().isServicesOptionsVisible());
        } else {
            assertThat("Services Options should not be visible",
                    getGroupDetailsPage().isServicesOptionsVisible());
        }
    }

    @Then("^I (do not )?see Timed Messages option on Group Details page$")
    public void seeTimedMessagesOption(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Timed Messages option should be visible",
                    getGroupDetailsPage().isTimedMessagesOptionVisible());
        } else {
            assertThat("Timed Messages Option should not be visible",
                    getGroupDetailsPage().isTimedMessagesOptionInvisible());
        }
    }

    /**
     * Checks if read receipts toggle is present on Group Details page
     */
    @Then("^I (do not )?see the Read Receipts toggle on Group Details page$")
    public void seeToggleReadReceipts(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Read receipts toggle should be visible",
                    getGroupDetailsPage().isReadReceiptsVisible());
        } else {
            assertThat("Read receipts toggle should not be visible",
                    getGroupDetailsPage().isReadReceiptsInvisible());
        }
    }

    /**
     * Checks if legal hold indicator is visible on group details page
     *
     * @param shouldNotSee equals to null if indicator should be visible
     */
    @Then("^I (do not )?see legal hold indicator on Group Details page$")
    public void seeLegalHoldIndicator(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Legal hold indicator should be visible",
                    getGroupDetailsPage().isLegalHoldIndicatorVisible());
        } else {
            assertThat("Legal hold indicator should not be visible",
                    getGroupDetailsPage().isLegalHoldIndicatorInvisible());
        }
    }

    @When("^I tap legal hold indicator on Group Details page$")
    public void iTapLegalHoldIndicator() {
        getGroupDetailsPage().tapLegalHoldIndicator();
    }

    @When("^I (do not )?see the Members section on Conversation Details page$")
    public void iSeeMembersSection(String doNot) {
        if (doNot == null) {
            assertThat("Members section should be visible", getGroupDetailsPage().isMembersSectionVisible());
        } else {
            assertThat("Members section is visible while it should not be", getGroupDetailsPage().isMembersSectionInvisible());
        }
    }

    @When("^I (do not )?see user (.*) in the Admins section$")
    public void iSeeUserInAdminsSection(String doNot, String userName) {
        userName = context.getUsersManager().replaceAliasesOccurrences(userName, ClientUsersManager.FindBy.NAME_ALIAS);
        if (doNot == null) {
            assertThat(String.format("User %s is expected to be in the Admins section, but is not", userName), getGroupDetailsPage().isUserInAdminsSection(userName));
        } else {
            assertThat(String.format("User %s is displayed in the Admins section, but should not", userName), getGroupDetailsPage().isUserNotInAdminsSection(userName));
        }
    }

    @When("^I (do not )?see the Show All button in the Admins section$")
    public void iSeeSeeAllButtonInAdminsSection(String doNot) {
        if (doNot == null) {
            assertThat("The See All button is expected to be visible in the Admins section, but it's not", getGroupDetailsPage().isSeeAllButtonVisibleInAdminsSection());
        } else {
            assertThat("The See All button should not be displayed in the Admins section, but it is", getGroupDetailsPage().isSeeAllButtonInvisibleInAdminsSection());
        }
    }

    @When("^I tap the Show All button$")
    public void iTapSeeAllButton() {
        getGroupDetailsPage().tapSeeAllButton();
    }
}

