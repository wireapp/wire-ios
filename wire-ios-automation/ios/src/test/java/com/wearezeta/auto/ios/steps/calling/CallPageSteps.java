package com.wearezeta.auto.ios.steps.calling;

import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.calling.CallPage;
import com.wearezeta.auto.ios.pages.calling.VideoCallingOverlayPage;
import io.cucumber.java.en.And;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.util.List;
import java.util.stream.Collectors;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.not;

public class CallPageSteps {

    IOSTestContext context;

    public CallPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CallPage getCallPage() {
        return context.getPagesCollection().getPage(CallPage.class);
    }

    private VideoCallingOverlayPage getPage() {
        return context.getPagesCollection().getPage(VideoCallingOverlayPage.class);
    }

    /**
     * Verify whether calling overlay is visible or not
     *
     * @param shouldNotBeVisible equals to null if the overlay should be visible
     */
    @Then("^I (do not )?see Calling overlay$")
    public void ISeeCallingOverlay(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("Calling overlay is not visible", getPage().iSeeLeaveCallButton());
        } else {
            assertThat("Calling overlay is visible, but should be hidden", getPage().iDontSeeLeaveCallButton());
        }
    }

    @When("^I tap Accept button on (?:the |\\s*)Calling overlay$")
    public void ITapAcceptButton() {
        getPage().tapAcceptButton();
    }

    @When("^I tap Leave button on Calling overlay$")
    public void iTapLeaveButton(){
        getPage().tapDeclineButton();
    }

    @When("^I tap Minimize button on Calling overlay$")
    public void iTapMinimizeButton(){
        getPage().iTapMinimize();
    }

    @When("^I swipe up to see the participants list$")
    public void iSwipeUpParticipantsList(){
        getPage().swipeUpParticipantsList();
    }

    @When("^I tap OK button on permission alert if visible$")
    public void iTapOK(){
        getPage().tapOKButton();
    }

    @Then("^I see End Call button on Calling overlay$")
    public void ISeeButton() {
        assertThat("End Call button is not visible", getPage().iSeeLeaveCallButton());
    }

    /**
     * Verify that call status message contains the particular text
     *
     * @param text the message to verify. This can contain user names
     */
    @When("^I see call status message contains \"(.*)\"$")
    public void ISeeCallStatusMessage(String text) {
        text = context.getUsersManager()
                .replaceAliasesOccurrences(text, ClientUsersManager.FindBy.NAME_ALIAS);
        assertThat(String.format("Call status message containing '%s' is not visible", text),
                getPage().isCallingMessageContainingVisible(text));
    }

    /**
     * Verify CBR indicator is visible or invisible
     */
    @Then("^I (do not )?see call indicator CONSTANT BIT RATE")
    public void ISeeCBRIndicator(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
	    assertThat("Call indicator CONSTANT BIT RATE is not visible", getPage().isBitRateLabelVisible());
        } else {
            assertThat("Call indicator CONSTANT BIT RATE is visible", getPage().isBitRateLabelInvisible());
        }
    }

    @Then("^I (do not )?see label call indicator CONSTANT BIT RATE")
    public void ISeeLabelCBRIndicator(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("Call indicator label CONSTANT BIT RATE is not visible",
                    getCallPage().isCBRLabelVisible());
        } else {
            assertThat("Call indicator label CONSTANT BIT RATE is visible",
                    getCallPage().isCBRLabelInvisible());
        }
    }

    /**
     * Verify VBR indicator is visible or invisible
     */
    @Then("^I (do not )?see call indicator VARIABLE BIT RATE")
    public void ISeeVBRIndicator(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("Call indicator VARIABLE BIT RATE is not visible", getPage().isBitRateLabelVisible());
        } else {
            assertThat("Call indicator VARIABLE BIT RATE is visible", getPage().isBitRateLabelInvisible());
        }
    }

    private static final Timedelta CALL_PARTICIPANTS_VISIBILITY_TIMEOUT = Timedelta.ofSeconds(20);

    /**
     * Verifies a number of participants in the calling overlay
     *
     * @param expectedNumber the expected number of avatars
     */
    @Then("^I see (\\d+) participants? on the Calling overlay$")
    public void ISeeXAvatars(int expectedNumber) {
        assertThat(
                String.format("The actual number of calling avatars is not equal to the expected number %s",
                        expectedNumber),
                getPage().isCountOfParticipantsEqualTo(expectedNumber, CALL_PARTICIPANTS_VISIBILITY_TIMEOUT)
        );
    }

    /**
     * Tap the top bar in order to restore the previously minimized overlay
     */
    @And("^I restore Calling overlay$")
    public void iRestoreOverlay() {
        getPage().tapRestoreButton();
    }

    /**
     * Verify whether minimized calling overlay bar is visible on the top of the screen
     */
    @Then("^I see that Calling overlay is minimized$")
    public void iSeeMinimizedOverlay() {
        assertThat("Calling overlay is expected to be minimized",
                getPage().isRestoreButtonVisible());
    }

    @When("^I tap Ok Button on Enterprise alert$")
    public void iTapOkButton() {
        getPage().tapOKButton();
    }

    @Then("^I (do not )?see SECURITY LEVEL: UNCLASSIFIED label on calling overlay$")
    public void ISeeUnclassifiedLabelOnCallingOverlay(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Unclassified label is not visible", getPage().isUnclassifiedLabelVisibleOnCallingOverlay());
        } else {
            assertThat("Unclassified label is not visible", getPage().isUnclassifiedLabelInvisibleOnCallingOverlay());
        }
    }

    @Then("^I (do not )?see SECURITY LEVEL: VS-NfD label on calling overlay$")
    public void ISeeClassifiedLabelOnCallingOverlay(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Classified label is not visible", getPage().isClassifiedLabelVisibleOnCallingOverlay());
        } else {
            assertThat("Classified label is not visible", getPage().isClassifiedLabelInvisibleOnCallingOverlay());
        }
    }
}