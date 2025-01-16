package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ManageDevicesOverlay;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class ManageDeviceOverlaySteps {
    IOSTestContext context;

    public ManageDeviceOverlaySteps(IOSTestContext context) {
        this.context = context;
    }

    private ManageDevicesOverlay getManageDevicesOverlay()  {
        return context.getPagesCollection().getPage(ManageDevicesOverlay.class);
    }

    /**
     * Verify whether Manage Devices overlay is visible
     *
     * @param shouldNotSee equals to null if the overlay should be visible
     */
    @Then("^I (do not )?see Manage Devices overlay$")
    public void iSeeManageDevicesOverlay(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("Manage Devices overlay is not visible",
                    getManageDevicesOverlay().waitUntilVisible());
        } else {
            assertThat("Manage Devices overlay is visible",
                    getManageDevicesOverlay().waitUntilInvisible());
        }
    }

    /**
     * Tap Mange Devices button
     *
     */
    @When("^I tap Manage Devices button on Devices Overlay$")
    public void iTapMangeDevicesButton()  {
        getManageDevicesOverlay().tapMangeDevicesButton();
    }

    @Then("^I tap Delete for device (.*)$")
    public void iTapDeleteForDevice(String deviceName) {
        getManageDevicesOverlay().tapDeleteButtonForDevice(deviceName);
    }

    @Then("^I tap Delete button on Devices Overlay$")
    public void iTapDeleteButtonOnDevicesOverlay() {
        getManageDevicesOverlay().tapDeleteButton();
    }
}
