package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ActionsSheetPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class ConversationActionsPageSteps {
    IOSTestContext context;

    public ConversationActionsPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ActionsSheetPage getPage() {
        return context.getPagesCollection().getPage(ActionsSheetPage.class);
    }

    @And("^I (do not )?see (Clear Content…|Clear|Clear and leave) conversation action button$")
    public void ISeeXButtonInActionMenuClear(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
     }

    @And("^I (do not )?see (Delete Group…|Delete Group) conversation action button$")
    public void ISeeXButtonInActionMenuDelete(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
    }

    @And("^I (do not )?see (|Block…|Unblock…|Block|Unblock) conversation action button$")
    public void ISeeXButtonInActionMenuBlock(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
    }

    @And("^I (do not )?see (Remove From Group…|Remove From Group) conversation action button$")
    public void ISeeXButtonInActionMenuRemove(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
    }

    @And("^I (do not )?see (Leave Group…|Leave) conversation action button$")
    public void ISeeXButtonInActionMenuLeave(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
    }

    @And("^I (do not )?see (Mute|Unmute) conversation action button$")
    public void ISeeXButtonInActionMenuMute(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
    }

    @And("^I (do not )?see (Cancel|Connect|Archive|Unarchive|Cancel Request) conversation action button$")
    public void ISeeXButtonInActionMenu(String shouldNotSee, String buttonTitle) {
        if (shouldNotSee == null) {
            assertThat(String.format("Menu item '%s' should be visible", buttonTitle),
                    getPage().isItemVisible(buttonTitle));
        } else {
            assertThat(String.format("Menu item '%s' should not exist", buttonTitle),
                    getPage().isItemInvisible(buttonTitle));
        }
    }

    /**
     * Tap the corresponding button to confirm/decline conversation action
     *
     * @param actionType either `confirm` or `decline`
     */
    @Then("^I (confirm|decline) conversation action$")
    public void doAction(String actionType) {
        if (actionType.equalsIgnoreCase("confirm")) {
            getPage().confirm();
        } else {
            getPage().decline();
        }
    }

    @When("^I tap (Clear Content…|Clear|Clear and leave) conversation action button$")
    public void tapClearContentActionButton(String buttonTitle) { getPage().tapMenuItem(buttonTitle); }

    @When("^I tap (Delete Group…|Delete Group) conversation action button$")
    public void tapDeletegroupActionButton(String buttonTitle) { getPage().tapMenuItem(buttonTitle); }

    @When("^I tap (Notifications…|Everything|Mentions and Replies|Nothing) conversation action button$")
    public void tapNotificationsActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @When("^I tap (Block…|Unblock…|Block|Unblock) conversation action button$")
    public void tapBlockActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @When("^I tap Move to… conversation action button$")
    public void tapMoveToActionButton() {
        getPage().tapMenuItem("Move to…");
    }

    @When("^I tap Remove from \"(.*)\" conversation action button$")
    public void tapRemoveFromFolderActionButton(String buttonTitle) {
        getPage().tapMenuItem(String.format("Remove from \"%s\"", buttonTitle));
    }

    @When("^I tap (Remove From Group…|Remove From Group|Remove) conversation action button$")
    public void tapRemoveFromGroupActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @When("^I tap (Leave Group…|Leave) conversation action button$")
    public void tapLeaveActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @When("^I tap (Mute|Unmute) conversation action button$")
    public void tapMuteActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @When("^I tap (Add to Favorites|Remove from Favorites) conversation action button$")
    public void tapFavoritesActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @When("^I tap (Cancel|Archive|Unarchive|Cancel Request|Revoke Link) conversation action button$")
    public void tapCommonActionButton(String buttonTitle) {
        getPage().tapMenuItem(buttonTitle);
    }

    @Then("^I (do not )?see action sheet contains text \"(.*)\"$")
    public void ISeeAlertContains(String shouldNotBeVisible, String expectedText) {
        if (shouldNotBeVisible == null) {
            assertThat(String.format("There is no '%s' text on the alert", expectedText),
                    getPage().isActionSheetContainsText(expectedText));
        } else {
            assertThat(String.format("There is '%s' text on the alert", expectedText),
                    getPage().isActionSheetDoesNotContainsText(expectedText));
        }
    }
}