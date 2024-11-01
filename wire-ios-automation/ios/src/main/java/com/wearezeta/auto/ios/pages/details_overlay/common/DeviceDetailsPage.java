package com.wearezeta.auto.ios.pages.details_overlay.common;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class DeviceDetailsPage extends IOSPage {

    // TODO: Once the accessibility identifier for the device verified switch is fixed, clean this up
    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeSwitch[`value == \"0\"`][2]")
    private WebElement verifySwitcher;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Device verified' AND name == 'Device verified' AND type == 'XCUIElementTypeSwitch'")
    private WebElement verifyDeviceSwitcher;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Verified' AND name == 'device verified' AND type == 'XCUIElementTypeSwitch'")
    private WebElement verifySelfDeviceSwitcher;

    @iOSXCUITFindBy(accessibility = "fingerprint")
    private WebElement fingerprint;

    @iOSXCUITFindBy(accessibility = "Remove Device")
    private WebElement removeDevice;

    @iOSXCUITFindBy(accessibility = "Go back to device overview")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "Back")
    private WebElement backButtonDeviceDetails;

    @iOSXCUITFindBy(accessibility = "Go back to device list")
    private WebElement backButtonDeviceList;

    @iOSXCUITFindBy(accessibility = "Revoked")
    private WebElement revoked;

    private static final Function<String, By> predicateText = text -> MobileBy.iOSNsPredicateString(String.format("type == 'XCUIElementTypeLink' AND value CONTAINS '%s'", text));

    public DeviceDetailsPage(WebDriver driver) {
        super(driver);
    }

    public void tapVerifyToggle() {
        if (isElementVisible(verifySwitcher)){
            verifySwitcher.click();}
        else if (isElementVisible(verifyDeviceSwitcher)){
            verifyDeviceSwitcher.click();
        } else {
            verifySelfDeviceSwitcher.click();
        }
    }

    public void tapBackButton() {
        if (isElementVisible(backButton)){
            backButton.click();
        } else if (isElementVisible(backButtonDeviceDetails)) {
            backButtonDeviceDetails.click();
        } else {
            backButtonDeviceList.click();
        }
    }

    public void tapRemoveDeviceButton() {
        removeDevice.click();
    }

    public boolean isDeviceRevoked() {
        return revoked.isDisplayed();
    }
}
