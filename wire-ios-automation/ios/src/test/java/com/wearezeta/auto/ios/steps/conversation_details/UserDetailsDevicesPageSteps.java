package com.wearezeta.auto.ios.steps.conversation_details;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.common.UserDetailsDevicesPage;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class UserDetailsDevicesPageSteps {
    IOSTestContext context;

    public UserDetailsDevicesPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private UserDetailsDevicesPage getUserDetailsDevicesPage()  {
        return context.getPagesCollection().getPage(UserDetailsDevicesPage.class);
    }

    /**
     * Open the details page of corresponding device on conversation details page
     *
     * @param deviceIndex the device index. Starts from 1
     */
    @When("^I open details page of device number (\\d+) on Devices tab$")
    public void IOpenDeviceDetails(int deviceIndex)  {
        deviceIndex++;
        getUserDetailsDevicesPage().openDeviceDetailsPage(deviceIndex);
    }

    /**
     * Checks the number of devices in participant devices tab
     *
     * @param expectedNumDevices Expected number of devices
     */
    @When("^I see (\\d+) items? (?:is|are) shown on Devices tab$")
    public void ISeeDevicesShownInDevicesTab(int expectedNumDevices)  {
        expectedNumDevices++;
        assertThat(
                String.format("The expected number of devices: %s is not equals to actual count", expectedNumDevices),
                getUserDetailsDevicesPage().isParticipantDevicesCountEqualTo(expectedNumDevices)
        );
    }

    @When("^I see legal hold device as first item on Devices tab$")
    public void ISeeLegalHoldDeviceAsFirstItem()  {
        assertThat(
                "The legal hold device is not the first item", getUserDetailsDevicesPage().isLegalHoldTheFirstDevice());
    }

    @When("^I see the label (Verified|Not Verified) is shown on user details page for the device number (\\d+)$")
    public void ISeeLabelForDeviceItem(String label, int deviceNumber)  {
        if (label.equals("Not Verified")) {
            assertThat(
                    String.format("The label Legal Hold is not visible for device number %s", deviceNumber), getUserDetailsDevicesPage().isDeviceNumberNotVerified(deviceNumber));
        } else {
            assertThat(
                    String.format("The label Verified is not visible for device number %s", deviceNumber), getUserDetailsDevicesPage().isDeviceNumberVerified(deviceNumber));
        }
    }
}
