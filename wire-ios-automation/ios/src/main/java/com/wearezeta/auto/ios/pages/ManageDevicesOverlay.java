package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.WebElement;

public class ManageDevicesOverlay extends IOSPage{
    @iOSXCUITFindBy(accessibility = "manage_devices")
    private WebElement manageDevicesButton;

    @iOSXCUITFindBy(accessibility = "Delete")
    private WebElement deleteDeviceButton;

    public ManageDevicesOverlay(WebDriver driver) {
        super(driver);
    }

    public boolean waitUntilVisible() {
        return manageDevicesButton.isDisplayed();
    }

    public boolean waitUntilInvisible() {
        return waitUntilElementInvisible(manageDevicesButton);
    }

    public void tapMangeDevicesButton() {
        manageDevicesButton.click();
    }

    private String removeStringFor(String deviceName) {
        return String.format("name CONTAINS 'Remove %s'", deviceName);
    }

    public void tapDeleteButtonForDevice(String deviceName) {
        getDriver().findElement(MobileBy.iOSNsPredicateString(removeStringFor(deviceName))).click();
    }

    public void tapDeleteButton() {
        deleteDeviceButton.click();
    }
}
