package com.wearezeta.auto.ios.steps.settings;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.single.SelfProfilePage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.awt.image.BufferedImage;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.hasItem;

public class SelfProfilePageSteps {
    IOSTestContext context;

    public SelfProfilePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SelfProfilePage getPage() {
        return context.getPagesCollection().getPage(SelfProfilePage.class);
    }

    @When("^I tap Add Account button on Self profile page$")
    public void iTapAddAccount() {
        getPage().tapAddAccountButton();
    }

    @When("^I tap Manage Team button on Self profile page$")
    public void iTapManageTeam() {
        getPage().tapManageTeam();
    }

/**
   @When("^I tap Settings button on Self profile page$")
    public void iTapSettingsButton() {
        getPage().tapSettingsButton();
    } */

    /**
        * Tap the picture preview self profile page
        */
    @When("^I tap my picture preview on Self profile page$")
    public void IPicturePreview() {
        getPage().tapProfilePicture();
    }
    @When("^I tap on set a status button on self profile page$")
    public void ITapSetStatusButton() {
        getPage().tapSetStatusButton();
    }

    @When("^I tap on profile close button$")
    public void ITapProfileCloseButton() {
        getPage().tapProfileCloseButton();
    }
    /**
     * Verify user details on Selfprofile page
     *
     * @param shouldNotSee equals to null if the corresponding details should be visible
     * @param value        user name or unique username or Address Book name
     * @param fieldType    one of available field types
     */
    @When("^I (do not )?see (name|unique username|team name|sso username) \"(.*)\" on Self profile page$")
    public void ISeeLabel(String shouldNotSee, String fieldType, String value) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        if (shouldNotSee == null) {
            value = value.trim().replaceAll("^\"|\"$", "");
            assertThat(String.format("'%s' field is expected to be visible", value),
                    getPage().isUserDetailVisible(fieldType, value));
        } else {
            value = value.trim().replaceAll("^\"|\"$", "");
            assertThat(String.format("'%s' field is expected to be invisible", value),
                    getPage().isUserDetailInvisible(fieldType, value));
        }
    }

    private static final Timedelta PROFILE_PICTURE_CHANGE_TIMEOUT = Timedelta.ofSeconds(7);
    private static final double PROFILE_PICTURE_MAX_SCORE = 0.7;

    /**
     * Verify whether self profile picture has been changed or not
     *
     * @param shouldNotBeChanged equals to null if the picture should stay the same
     */
    @Then("^I see the picture is (not )?changed on Self profile page$")
    public void IVerifyPicture(String shouldNotBeChanged) throws Exception {
        if (shouldNotBeChanged == null) {
            assertThat("Self profile picture is still the same",
                    context.getProfilePictureState().isChanged(PROFILE_PICTURE_CHANGE_TIMEOUT, PROFILE_PICTURE_MAX_SCORE));
        } else {
            assertThat("Self profile picture is expected to be the same",
                    context.getProfilePictureState().isNotChanged(PROFILE_PICTURE_CHANGE_TIMEOUT, PROFILE_PICTURE_MAX_SCORE));
        }
    }
}
