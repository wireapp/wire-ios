package com.wearezeta.auto.ios.steps.settings;

import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.backend.models.AccentColor;
import com.wearezeta.auto.common.email.messages.AccountDeletionMessage;
import com.wearezeta.auto.common.email.messages.ActivationMessage;
import com.wearezeta.auto.common.email.messages.WireMessage;
import com.wearezeta.auto.common.email.handlers.ISupportsMessagesPolling;
import com.wearezeta.auto.common.email.MailboxProvider;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.SettingsPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;

public class SettingsPageSteps {
    IOSTestContext context;

    public SettingsPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SettingsPage getSettingsPage() {
        return context.getPagesCollection().getPage(SettingsPage.class);
    }

    @When("^I select settings item Devices")
    public void ISelectDevicesItem() {
        getSettingsPage().tapDevices();
    }

    @When("^I select settings item Account")
    public void ISelectAccountItem() {
        getSettingsPage().tapAccount();
    }

    @When("^I select settings item Back Up Conversations")
    public void ISelectBackUpConversationsItem() {
        getSettingsPage().tapBackUpConversations();
    }

    @When("^I select settings item Options")
    public void ISelectOptionsItem() {
        getSettingsPage().tapOptionsItem();
    }

    @When("^I select settings item Log Out")
    public void ISelectLogOutItem() {
        getSettingsPage().tapLogOutItem();
    }

    @When("^I select settings item Picture")
    public void ISelectPictureItem() {
        getSettingsPage().tapPictureItem();
    }

    @When("^I select settings item Reset Password")
    public void ISelectResetPasswordItem() {
        getSettingsPage().tapResetPasswordItem();
    }

    @When("^I select settings item Support")
    public void ISelectSupportItem() {
        getSettingsPage().tapSupportItem();
    }

    @When("^I select settings item Wire Support Website")
    public void ISelectWireSupportWebsiteItem() {
        getSettingsPage().tapWireSupportWebsiteItem();
    }

    @When("^I select settings item Terms of use")
    public void ISelectTermsOfUse() {
        getSettingsPage().tapTermsOfUse();
    }

    @When("^I select settings item Privacy Policy")
    public void ISelectPrivacyPolicy() {
        getSettingsPage().tapPrivacyPolicy();
    }

    @When("^I select settings item Wire Website")
    public void ISelectWireWebsite() {
        getSettingsPage().tapWireWebsite();
    }

    @When("^I select settings item Contact Support")
    public void ISelectContactSupport() {
        getSettingsPage().tapContactSupport();
    }

    @When("^I select settings item Report Misuse")
    public void ISelectReportMisuse() {
        getSettingsPage().tapReportMisuse();
    }

    @When("^I select settings item Delete Account")
    public void ISelectDeleteAccountItem() {
        getSettingsPage().tapDeleteAccountItem();
    }

    @When("^I select settings item Username")
    public void ISelectUsernameItem() {
        getSettingsPage().tapUsernameItem();
    }

    @When("^I select settings item Email")
    public void ISelectEmailItem() {
        getSettingsPage().tapEmailItem();
    }

    @When("^I select settings item Name")
    public void ISelectNameItem() {
        getSettingsPage().tapNameItem();
    }

    @When("^I select settings item About")
    public void ISelectAboutItem() {
        getSettingsPage().tapAboutItem();
    }

    @When("^I select settings item Color")
    public void ISelectColorItem() {
        getSettingsPage().tapColorItem();
    }

    @When("^I select color Purple on Profile Color page")
    public void ISelectColorPurple() {
        getSettingsPage().tapColorPurple();
    }

    @When("^I clear Username input field on Settings page$")
    public void iClearUsername() {
        getSettingsPage().clearUsername();
    }


    /**
     * Verify the current value of a setting
     *
     * @param itemName      setting option name
     * @param expectedValue the expected value. Can be user name/email/phone number alias
     */
    @Then("^I verify the value of settings item (.*) equals to \"(.*)\"")
    public void IVerifySettingsItemValue(String itemName, String expectedValue) {
        expectedValue = context.getUsersManager()
                .replaceAliasesOccurrences(expectedValue, ClientUsersManager.FindBy.EMAIL_ALIAS,
                        ClientUsersManager.FindBy.NAME_ALIAS);
        assertThat(String.format("The value of '%s' setting item is not equal to '%s'", itemName, expectedValue),
                getSettingsPage().isSettingItemValueEqualTo(itemName, expectedValue));
    }

    @When("^I see the text on VBR toggle in settings$")
    public void ISeeVBRText() {
        getSettingsPage().iSeeVBRText();
    }

    /**
     * Verify whether the corresponding settings menu item is visible
     *
     * @param itemName the expected item name
     */
    @Then("^I (do not )?see settings item (.*)$")
    public void ISeeSettingsItem(String shouldNot, String itemName) {
        if (shouldNot == null) {
            assertThat(String.format("Settings menu item '%s' is not visible", itemName),
                    getSettingsPage().isItemVisible(itemName));
        } else {
            assertThat(String.format("Settings menu item %s is visible", itemName),
                    getSettingsPage().isItemInvisible(itemName));
        }
    }

    /**
     * Start monitoring for account removal email confirmation
     *
     * @param name user name/alias
     */
    @When("^I start waiting for (.*) account removal notification$")
    public void IStartWaitingForAccountRemovalConfirmation(String name) throws Exception {
        final ClientUser forUser = context.getUsersManager()
                .findUserByNameOrNameAlias(name);

        final Map<String, String> expectedHeaders = new HashMap<>();
        expectedHeaders.put(WireMessage.ZETA_PURPOSE_HEADER_NAME, AccountDeletionMessage.MESSAGE_PURPOSE);

        ISupportsMessagesPolling mailbox = MailboxProvider.getInstance(BackendConnections.get(forUser),
                forUser.getEmail());
        context.setAccountRemovalConfirmation(
                mailbox.getMessage(expectedHeaders, AccountDeletionMessage.DELETION_RECEIVING_TIMEOUT));
    }

    /**
     * Make sure the account removal link is received
     */
    @Then("^I verify account removal notification is received$")
    public void IVerifyAccountRemovalNotificationIsReceived() throws Exception {
        if (context.getAccountRemovalConfirmation() == null) {
            throw new IllegalStateException("Please init email confirmation listener first");
        }
        new AccountDeletionMessage(context.getAccountRemovalConfirmation().get());
    }

    /**
     * Take a screenshot of self profile page and save it into internal var
     */
    @When("^I remember my current profile picture$")
    public void IRememberMyProfilePicture() throws Exception {
        context.setProfilePictureState(() -> getSettingsPage().takeScreenshot().
                orElseThrow(() -> new IllegalStateException("Cannot take a screenshot of self profile page")));
    }

    @When("^I tap X navigation button on Settings page$")
    public void iTapX() {
        getSettingsPage().tapX();
    }

    @When("^I tap (Done|Back|Edit|Save|X|Go back to Settings|Go back to Setting|Go back to Account|Go back to device list) navigation button on Settings page$")
    public void ITapNavigationButton(String name) {
        getSettingsPage().tapNavigationButton(name);
    }

    @When("^I clear Name input field on Settings page$")
    public void IClearSelfName() {
        getSettingsPage().clearSelfName();
    }

    @When("^I set \"(.*)\" value to Name input field on Settings page$")
    public void ISetSelfName(String newValue) {
        newValue = context.getUsersManager()
                .replaceAliasesOccurrences(newValue, ClientUsersManager.FindBy.NAME_ALIAS);
        getSettingsPage().setSelfName(newValue);
    }

    private static final Timedelta COLOR_PICKER_STATE_CHANGE_TIMEOUT = Timedelta.ofSeconds(10);
    private static final double MIN_COLOR_PICKER_SIMILARITY_SCORE = 0.999;

    /**
     * Get and remember the screenshot of People Picker
     */
    @When("^I remember the state of Color Picker$")
    public void IRememberColorPickerState() throws Exception {
        context.setColorPickerState(() -> getSettingsPage().getColorPickerStateScreenshot());
    }

    /**
     * Verify that color picker state has been changed
     */
    @Then("^I verify the state of Color Picker is changed$")
    public void IVerifyColorPickerState() throws Exception {
        assertThat("Color Picker state has not been changed",
                context.getColorPickerState().isChanged(COLOR_PICKER_STATE_CHANGE_TIMEOUT, MIN_COLOR_PICKER_SIMILARITY_SCORE));
    }

    /**
     * Changes the accent color by clicking the color picker
     *
     * @param color one of possible color values
     */
    @When("^I set my accent color to (StrongBlue|StrongLimeGreen|BrightYellow|VividRed|BrightOrange|SoftPink|Violet)" +
            " on Settings page$")
    public void IChangeMyAccentColor(String color) {
        getSettingsPage().selectAccentColor(AccentColor.getByName(color));
    }

    @Then("^I see \"(.*)\" unique username is displayed on Settings Page$")
    public void ISeeUniqueUsernameOnSettingsPage(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        assertThat(String.format("Unique username %s is not displayed on Settings Page", name),
                getSettingsPage().isUniqueUsernameInSettingsDisplayed(name));
    }

    @Then("^I see unique username and domain of user (.*) is displayed on Settings Page$")
    public void ISeeUniqueUsernameAndDomainOnSettingsPage(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        String domainName = BackendConnections.get(user).getDomain();
        String name = user.getUniqueUsername() + "@" + domainName;
        assertThat(String.format("Unique username %s is not displayed on Settings Page", name),
                getSettingsPage().isUniqueUsernameInSettingsDisplayed(name));
    }

    /**
     * Tap X button on color picker control
     */
    @When("^I close accent color picker on Settings page$")
    public void ICloseColorPicker() {
        getSettingsPage().closeColorPicker();
    }

    /**
     * Change and commit email address
     *
     * @param newEmail new email address/alias
     */
    @When("^I change email address to (.*) on Settings page$")
    public void IChangeEmailAddress(String newEmail) {
        newEmail = context.getUsersManager()
                .replaceAliasesOccurrences(newEmail, ClientUsersManager.FindBy.EMAIL_ALIAS);
        // TODO Continue investigating why this has to be performed two times to pass, maybe has to do with XCode 11.3? -> run regression on this branch with double clear disabled
//        getSettingsPage().clearEmailAddress();
        getSettingsPage().changeEmailAddress(newEmail);
    }

    /**
     * Wait until the "check you email" label disappears from the UIand email address
     * verification is detected by SE
     */
    @When("^I wait until the UI detects successful email activation on Settings page$")
    public void IWaitForActivation() {
        final Duration timeout = Duration.ofSeconds(ActivationMessage.ACTIVATION_TIMEOUT.asSeconds());
        if (!getSettingsPage().waitUntilEmailVerificationHappens(timeout)) {
            throw new IllegalStateException(
                    String.format("The UI didn't detect email activation after %s", timeout)
            );
        }
    }

    @When("^I toggle send read receipts on account page$")
    public void iToggleSendReadReceiptsOnAccountPage() {
      getSettingsPage().switchToggleReadReceipts();
    }

    @Then("^I can not change display name on Settings page$")
    public void iCannotChangeDisplayName()  {
        assertThat("Name input IS visible",
                getSettingsPage().isDisplayNameInputFieldStatic());
    }

    @Then("^I can not change unique username on Settings page$")
    public void iCannotChangeUniqueUsername()  {
        assertThat("unique username input IS visible",
                getSettingsPage().isUniqueUsernameInputFieldStatic());
    }

    @Then("^I do not see Appearance section on Settings page$")
    public void iDoNotSeeAppearanceSection()  {
        assertThat("Appearance section IS visible",
                getSettingsPage().isAppearanceSectionInvisible());
    }

    @Then("^I (do not )?see the beta toggle$")
    public void iSeeTheBetaToggle(String doNot) {
        if (doNot == null) {
            assertThat("Beta toggle is not visible",
                    getSettingsPage().isBetaToggleVisible());
        } else {
            assertThat("Beta toggle is visible while it should not be",
                    getSettingsPage().isBetaToggleInvisible());
        }
    }

    @Then("^I see the beta toggle is (un)?checked$")
    public void isBetaToggleChecked(String notChecked) {
        if(notChecked == null) {
            assertThat("Beta toggle is not checked",
                    getSettingsPage().isBetaToggleChecked());
        } else {
            assertThat("Beta toggle is checked",
                    getSettingsPage().isBetaToggleUnchecked());
        }
    }

    @Then("^I tap the beta toggle$")
    public void iTapBetaToggle() {
        getSettingsPage().tapBetaToggle();
    }

    @Then("^I see domain name of user (.*) on settings item Domain$")
    public void iSeeDomainName(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        String domainName = BackendConnections.get(user).getDomain();
        assertThat(String.format("Domain name on settings Domain is not equal to '%s'", domainName),
                    getSettingsPage().isDomainNameVisible(domainName));
    }

    @Then("^I (do not )?see team name as (.*) on settings item Team$")
    public void iSeeTeamName(String shouldNot, String domainName) {
        if (shouldNot == null) {
            assertThat(String.format("Team name on settings item Team is not equal to '%s'", domainName),
                    getSettingsPage().isTeamNameVisible(domainName));
        } else {
            assertThat(String.format("Team name on settings item Team is visible and equal to '%s'", domainName),
                    getSettingsPage().isTeamNameInvisible(domainName));
        }
    }

    @Then("^I see domain name of user (.*) on Username UI$")
    public void iSeeDomainNameUserNameUI(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        String domainName = "@" + BackendConnections.get(user).getDomain();
        assertThat(String.format("Domain name on username UI is not equal to '%s'", domainName),
                getSettingsPage().isDomainNameVisibleOnUsernameUI(domainName));
    }

    @Then("^I see domain name is not editable of user (.*) on Username UI$")
    public void iSeeNoNEditableDomainNameUserNameUI(String userAlias){
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        String domainName = "@" + BackendConnections.get(user).getDomain();
        assertThat(("Domain name on username UI is editable"), getSettingsPage().isNonEditableDomainNameFieldOnUsernameUI(domainName));
    }

    @Then("^I see domain name on settings item is not editable")
    public void iSeeNoNEditableDomainNameSettingsUI(){
        assertThat(("Domain name on settings UI is editable"), getSettingsPage().isDomainNonEditableOnSettings());
    }

    @Then("^I see team name on settings item is not editable")
    public void iSeeNoNEditableTeamNameSettingsUI(){
        assertThat(("Team name on settings UI is editable"), getSettingsPage().isTeamNonEditableOnSettings());
    }

    @When("I open the Advanced Settings menu")
    public void iOpenTheAdvancedSettingsMenu() {
        getSettingsPage().tapAdvanced();
    }

    @When("I tap on the account back button")
    public void iTapAccountBackButton() {
        getSettingsPage().tapAccountBackButton();
    }

    @When("I tap on the settings back button")
    public void iTapSettingsBackButton() {
        getSettingsPage().tapSettingsBackButton();
    }

    @When("^I toggle on lock with passcode option$")
    public void iOnLockWithPasscodeToggle() {
        getSettingsPage().OnLockWithPasscodeToggle();
    }

    @When("^I enter passcode (.*) to lock the app$")
    public void iInputLockPasscode(String passcode) {
        passcode = context.getUsersManager()
                .replaceAliasesOccurrences(passcode, ClientUsersManager.FindBy.PASSWORD_ALIAS);
        getSettingsPage().inputLockPasscode(passcode);
    }
@When("^I tap on lock passcode button$")
    public void iTapLockPasscodeButton() {
    getSettingsPage().tapLockPasscodeButton();
}
}

