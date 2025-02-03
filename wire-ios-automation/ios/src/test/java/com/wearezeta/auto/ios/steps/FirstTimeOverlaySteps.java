package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.FirstTimeOverlay;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class FirstTimeOverlaySteps {

    IOSTestContext context;

    public FirstTimeOverlaySteps(IOSTestContext context) {
        this.context = context;
    }

    private FirstTimeOverlay getOverlay() {
        return context.getPagesCollection().getPage(FirstTimeOverlay.class);
    }

    @Then("^I see First Time overlay$")
    public void iSeeOverlay()  {
        assertThat("Restore button is not visible", getOverlay().waitUntilVisible());
        assertThat("Overlay text wrong", getOverlay().isHeadingVisible());
    }

    @Then("^I do not see First Time overlay$")
    public void iDoNotSeeOverlay()  {
        assertThat("Restore button is still visible", getOverlay().waitUntilInvisible());
    }

    @When("^I accept First Time overlay$")
    public void iAccept()  {
        getOverlay().accept();
    }

    @When("^I tap Restore from backup button on First Time overlay$")
    public void iTapRestoreButton() {
        getOverlay().tapRestoreButton();
    }
}