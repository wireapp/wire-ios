package com.wearezeta.auto.ios.steps.conversation_details.single;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.ios.pages.details_overlay.single.UserProfilePopupPage;

public class UserProfilePopupPageSteps {
    private IOSTestContext context;

    public UserProfilePopupPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private UserProfilePopupPage getPage()  {
        return context.getPagesCollection().getPage(UserProfilePopupPage.class);
    }

    @Then("^I (do not )?see User profile popup page$")
    public void ISeeUserPopupPage(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The user profile popup page is not visible",
                    getPage().isUserProfilePopupVisible());
        } else {
            assertThat("The user profile popup page is still visible",
                    getPage().isUserProfilePopupInvisible());
        }
    }

    @When("^I tap X button on User profile popup page$")
    public void ITapXButton()  {
        getPage().tapXButton();
    }

    @When("^I tap Open Conversation button on User profile popup page$")
    public void ITapOpenConversationButton()  {
        getPage().tapOpenConversationButton();
    }

    @When("^I tap Open self profile button on User profile popup page$")
    public void ITapSelfProfileButton()  {
        getPage().tapSelfProfileButton();
    }

    @When("^I tap More Actions button on User profile popup page$")
    public void ITapMoreActionsButton()  {
        getPage().tapMoreActionsButton();
    }

    @Then("^I (do not )?see user name (.*) on User profile popup page$")
    public void ISeeDisplayName(String shouldNotSee, String value)  {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("User name '%s' is expected to be visible", value),
                    getPage().isUserNameVisible(value));
        } else {
            assertThat(String.format("\"User name '%s' field is expected to be visible", value),
                    getPage().isUserNameInvisible(value));
        }
    }

    @Then("^I (do not )?see unique user name (.*) on User profile popup page$")
    public void ISeeUniqueUserName(String shouldNotSee, String value)  {
        value = context.getUsersManager().
                replaceAliasesOccurrences(value, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("User name '%s' is expected to be visible", value),
                    getPage().isUniqueUserNameVisible(value));
        } else {
            assertThat(String.format("\"User name '%s' field is expected to be visible", value),
                    getPage().isUniqueUserNameInvisible(value));
        }
    }

    @Then("^I see profile picture on User profile popup page$")
    public void ISeeProfilePicture()  {
        assertThat("The profile picture is not visible on User profile popup page",
                getPage().isUserProfilePictureVisible());
    }

    @Then("^I (do not )?see Information label on User profile popup page$")
    public void ISeeInformationLabel(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The Information label is not visible on User profile popup page",
                    getPage().isInformationLabelVisible());
        } else {
            assertThat("The Information label is still visible on User profile popup page",
                    getPage().isInformationLabelInvisible());
        }
    }

    @Then("^I see key \"(.*)\" and value \"(.*)\" at cell (\\d+) on User profile popup page$")
    public void ISeeRichProfileKeyValuePair(String key, String value, int index)  {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.EMAIL_ALIAS);
        assertThat("The key value pair is not visible on User profile popup page",
                getPage().isInformationKeyValuePairVisible(key, value, index));
    }

    @And("^I swipe (down|up) on User profile popup page$")
    public void iSwipe(String direction) {
        getPage().swipe(IOSPage.SwipeDirection.valueOf(direction.toUpperCase()));
    }

    @Then("^I (do not )?see Open Conversation button on User profile popup page$")
    public void ISeeOpenConversationtButton(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The Open Conversation button is not visible on User profile popup page",
                    getPage().isOpenConversationButtonVisible());
        } else {
            assertThat("The Open Conversation button is still visible on User profile popup page",
                    getPage().isOpenConversationButtonInvisible());
        }
    }

    @Then("^I (do not )?see Connect button on User profile popup page$")
    public void ISeeConnectButton(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The Connect button is not visible on User profile popup page",
                    getPage().isConnectButtonVisible());
        } else {
            assertThat("The Connect button is still visible on User profile popup page",
                    getPage().isConnectButtonInvisible());
        }
    }

    @Then("^I (do not )?see More Actions button on User profile popup page$")
    public void ISeeMoreActionsButton(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The More Actions button is not visible on User profile popup page",
                    getPage().isMoreActionsButtonVisible());
        } else {
            assertThat("The More Actions button is still visible on User profile popup page",
                    getPage().isMoreActionsButtonInvisible());
        }
    }

    @Then("^I do not see Devices tab on User profile popup page$")
    public void IDoNotSeeDevicesTab() {
        assertThat("Devices should not be visible",
                getPage().isDevicesTabInvisible());
    }

    @Then("^I (do not )?see GUEST label on User profile popup page$")
    public void ISeeGuestLabel(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("GUEST label is expected to be visible ", getPage().isGuestLabelVisible());
        } else {
            assertThat("GUEST label is expected to be invisible ", getPage().isGuestLabelInvisible());
        }
    }
}
