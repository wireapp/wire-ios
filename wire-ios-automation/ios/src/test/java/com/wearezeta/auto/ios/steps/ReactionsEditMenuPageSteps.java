package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ReactionsEditMenuPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class ReactionsEditMenuPageSteps {

    IOSTestContext context;

    public ReactionsEditMenuPageSteps(IOSTestContext context) {
        this.context = context;
    }

    @Then("^I see menu with quick reactions and other items$")
    public void iSeeMenu() {
        assertThat("Menu with quick reactions and other items is not visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isVisible());
    }

    @When("^I tap on (.*) reaction in quick reactions$")
    public void iTapOnReaction(String reaction) {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).iTapQuickReaction(reaction);
    }

    @When("^I do not see forward button on edit menu$")
    public void iDontSeeForward() {
        assertThat("Forward button > still visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isForwardButtonInvisible());
    }

    @When("^I tap on Copy on edit menu$")
    public void iTapCopy() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapCopy();
    }

    @Then("^I see Copy on edit menu$")
    public void iSeeCopy() {
        assertThat("Edit menu item not visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isCopyVisible());
    }

    @Then("^I do not see Copy on edit menu$")
    public void iDoNotSeeCopy() {
        assertThat("Edit menu item still visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isCopyInvisible());
    }

    @When("^I tap on Delete on edit menu$")
    public void iTapDelete() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapDelete();
    }

    @Then("^I see Delete on edit menu$")
    public void iSeeDelete() {
        assertThat("Edit menu item not visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isDeleteVisible());
    }

    @When("^I tap on Details on edit menu$")
    public void iTapDetails() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapDetails();
    }

    @When("^I tap on Download on edit menu$")
    public void iTapDownload() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapDownload();
    }

    @Then("^I do not see Download on edit menu$")
    public void iDoNotSeeDownload() {
        assertThat("Edit menu item still visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isDownloadInvisible());
    }

    @When("^I tap on Edit on edit menu$")
    public void iTapEdit() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapEdit();
    }

    @When("^I tap on Like on edit menu$")
    public void iTapLike() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapLike();
    }

    @When("^I tap on Paste on edit menu$")
    public void iTapPaste() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapPaste();
    }

    @Then("^I do not see Paste on edit menu$")
    public void iDoNotSeePaste() {
        assertThat("Edit menu item still visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isPasteInvisible());
    }

    @When("^I tap on Reply on edit menu$")
    public void iTapReply() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapReply();
    }

    @Then("^I see Reply on edit menu$")
    public void iSeeReply() {
        assertThat("Edit menu item not visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isReplyVisible());
    }

    @When("^I tap on Save on edit menu$")
    public void iTapSave() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapSave();
    }

    @Then("^I see Save on edit menu$")
    public void iSeeSave() {
        assertThat("Edit menu item not visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isSaveVisible());
    }

    @Then("^I do not see Save on edit menu$")
    public void iDoNotSeeSave() {
        assertThat("Edit menu item still visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isSaveInvisible());
    }

    @When("^I tap on Select All on edit menu$")
    public void iTapSelectAll() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapSelectAll();
    }

    @When("^I tap on Share on edit menu$")
    public void iTapShare() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapShare();
    }

    @Then("^I see Share on edit menu$")
    public void iSeeShare() {
        assertThat("Edit menu item not visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isShareVisible());
    }

    @Then("^I do not see Share on edit menu$")
    public void iDoNotSeeShare() {
        assertThat("Edit menu item still visible",
                context.getPagesCollection().getPage(ReactionsEditMenuPage.class).isShareInvisible());
    }

    @When("^I tap on Cancel on edit menu$")
    public void iTapCancel() {
        context.getPagesCollection().getPage(ReactionsEditMenuPage.class).tapCancel();
    }
}
