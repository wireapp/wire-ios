package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.AdvancedSettingsPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.jcodec.common.Assert.assertTrue;

public class AdvancedSettingsSteps {
    IOSTestContext context;

    public AdvancedSettingsSteps(IOSTestContext context) {
    this.context = context;
  }

    public AdvancedSettingsPage getAdvancedSettingsPage() {
        return context.getPagesCollection().getPage(AdvancedSettingsPage.class);
    }

    @When("I open Version Technical Details")
    public void iOpenVersionTechnicalDetails() {
      getAdvancedSettingsPage().openVersionTechnicalDetails();
    }

    @Then("I see my version details")
    public void iSeeMyVersionDetails() {
        assertTrue("Version details are not displayed", getAdvancedSettingsPage().isVersionDetailsVisible());
    }
}
