package com.wearezeta.auto.ios.steps.settings;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.IOSPage;
import com.wearezeta.auto.ios.pages.details_overlay.common.UserSettingsDevicesPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class SelfDevicesPageSteps {
    IOSTestContext context;

    public SelfDevicesPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private UserSettingsDevicesPage getUserSettingsDevicesPage() {
        return context.getPagesCollection().getPage(UserSettingsDevicesPage.class);
    }

    /**
     * Open the details page of corresponding device on conversation details page
     *
     * @param deviceIndex the device index. Starts from 1
     */
    @When("^I open details page of device number (\\d+) on Settings page$")
    public void IOpenDeviceDetails(int deviceIndex) {
        getUserSettingsDevicesPage().openDeviceDetailsPage(deviceIndex);
    }

    /**
     * Presses the delete button for the particular device
     *
     * @param deviceName name of device that should be deleted
     */
    @When("^I tap Delete (.*) button on Settings page$")
    public void ITapDeleteButtonFromDevices(String deviceName) {
        getUserSettingsDevicesPage().tapDeleteDeviceButton(deviceName);
        getUserSettingsDevicesPage().tapDeleteButton();
    }

    /**
     * Types in the password and presses OK to confirm the device deletion
     *
     * @param password of user
     */
    @When("^I confirm with my (.*) the deletion of the device on Settings page$")
    public void IConfirmWithMyPasswordTheDeletionOfTheDevice(String password) {
        password = context.getUsersManager()
                .replaceAliasesOccurrences(password, ClientUsersManager.FindBy.PASSWORD_ALIAS);
        getUserSettingsDevicesPage().typePasswordToConfirmDeleteDevice(password);
        context.getPagesCollection().getPage(IOSPage.class).tapAlertButton("OK");
    }

    @Then("^I see wrong password dialog$")
    public void iSeeWrongPasswordDialog() {
        assertThat("No wrong password dialog", getUserSettingsDevicesPage().isWrongPasswordDialogVisible());
    }

    @When("^I tap Ok Button on wrong password dialog$")
    public void iClickOK() {
        getUserSettingsDevicesPage().tapOKOnWrongPasswordDialog();
    }

    /**
     * Verifies that device is or is not in device settings list
     *
     * @param shouldNot equals to null if the device is in list
     * @param device    name of device in list
     */
    @Then("^I (do not )?see device (.*) in devices list on Settings page$")
    public void ISeeDeviceInDevicesList(String shouldNot, String device) {
        if (shouldNot == null) {
            assertThat(String.format("The device %s is not visible in the device list", device),
                    getUserSettingsDevicesPage().isDeviceVisibleInList(device));
        } else {
            assertThat(String.format("The device %s is still visible in the device list", device),
                    getUserSettingsDevicesPage().isDeviceInvisibleInList(device));
        }
    }

    /**
     * Checks the number of devices in participant devices tab
     *
     * @param expectedNumDevices Expected number of devices
     */
    @Then("^I see (\\d+) devices? (?:is|are) shown on Settings page$")
    public void ISeeDevicesShownInDevicesTab(int expectedNumDevices)  {
        assertThat(
                String.format("The expected number of devices: %s is not equals to actual count", expectedNumDevices),
                getUserSettingsDevicesPage().isUserDevicesCountEqualTo(expectedNumDevices)
        );
    }

    @When("^I save the device id of the current device$")
    public void iSaveMyCurrentDevice() {
        String deviceID = getUserSettingsDevicesPage().getCurrentDeviceID();
        context.setCurrentDeviceId(deviceID);
    }

    @And("I open my remembered device")
    public void iOpenMyRememberedDevice() {
        getUserSettingsDevicesPage().openDeviceDetailsPageById(context.getCurrentDeviceId());
    }
}
