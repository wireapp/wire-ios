package com.wearezeta.auto.ios.steps.calling;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.calling.CallPage;
import com.wearezeta.auto.ios.pages.calling.VideoCallingOverlayPage;
import io.cucumber.java.en.Then;

import static org.hamcrest.MatcherAssert.assertThat;

public class VideoCallingOverlayPageSteps {

    IOSTestContext context;

    public VideoCallingOverlayPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CallPage getCallPage() {
        return context.getPagesCollection().getPage(CallPage.class);
    }

    private VideoCallingOverlayPage getVideoCallingOverlayPage() {
        return context.getPagesCollection().getPage(VideoCallingOverlayPage.class);
    }

    @Then("^I (do not )?see Video Calling overlay$")
    public void ISeeCallingOverlay(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("Video calling overlay is not visible",
                    getVideoCallingOverlayPage().iSeeLeaveCallButton());
        } else {
            assertThat("Video calling overlay is visible, but should be hidden",
                    getVideoCallingOverlayPage().iDontSeeLeaveCallButton());
        }
    }
    @Then("^I tap on active mute button$")
    public void  activeMuteButton(){
        getVideoCallingOverlayPage().tapActiveMuteButton();
    }
    @Then("^I tap on inactive mute button$")
    public void  inactiveMuteButton(){
        getVideoCallingOverlayPage().tapInactiveMuteButton();
    }

    @Then("^I (do not )?see alert about New device$")
    public void ISeeAlert(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("New device alert is not visible",
                    getVideoCallingOverlayPage().iSeeNewDeviceAlert());
        } else {
            assertThat("New device alert is visible, but should be hidden",
                    getVideoCallingOverlayPage().iDontSeeNewDeviceAlert());
        }
    }

    @Then("^I tap on screen to enable video calling overlay$")
    public void iTapOnScreen() {
        getVideoCallingOverlayPage().iTapOnScreen();
    }

    @Then("^I (do not )?see profile picture avatar for users (.*) on calling overlay$")
    public void iSeeAvatarAGroupudioParticipants(String doNot, String nameAliasses) {
        for (String name : context.getUsersManager().splitAliases(nameAliasses)) {
            final String username = context.getUsersManager()
                    .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
            if (doNot == null) {
                assertThat(String.format("'avatar profile picture' icon should be visible for participant %s", username),
                        getVideoCallingOverlayPage().iSeeAvatarGroupAudioParticipants(username));
            } else {
                assertThat(String.format("'avatar profile picture' icon should not be visible for participant %s", username),
                        getVideoCallingOverlayPage().iDontSeeGroupAvatarAudioParticipants(username));
            }
        }
    }
}
