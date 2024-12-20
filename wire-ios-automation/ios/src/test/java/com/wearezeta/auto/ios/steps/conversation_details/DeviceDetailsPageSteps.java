package com.wearezeta.auto.ios.steps.conversation_details;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.common.DeviceDetailsPage;
import static org.hamcrest.MatcherAssert.assertThat;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

public class DeviceDetailsPageSteps {
    IOSTestContext context;

    public DeviceDetailsPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private DeviceDetailsPage getDeviceDetailsPage()  {
        return context.getPagesCollection().getPage(DeviceDetailsPage.class);
    }

    @When("^I tap Verify (?:button|switcher) on Device Details page$")
    public void ITapVerifyToggle()  {
        getDeviceDetailsPage().tapVerifyToggle();
    }

    @When("^I tap Back (?:button|switcher) on Device Details page$")
    public void ITapBackButton()  {
        getDeviceDetailsPage().tapBackButton();
    }

    @When("^I tap Remove Device (?:button|switcher) on Device Details page$")
    public void ITapRemoveDeviceButton()  {
        getDeviceDetailsPage().tapRemoveDeviceButton();
    }

    @Then("I should see a revoked certificate in Device Details")
    public void iShouldSeeARevokedCertificateInDeviceDetails() {
        assertThat("Device should be revoked", getDeviceDetailsPage().isDeviceRevoked());
    }
}
