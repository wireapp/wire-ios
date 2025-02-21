package com.wearezeta.auto.ios.pages.details_overlay.common;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.AppiumBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class UserSettingsDevicesPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"device proteus ID\"`][1]")
    private WebElement deviceID;

    @iOSXCUITFindBy(accessibility = "Delete")
    private WebElement deleteButton;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeSecureTextField' AND value CONTAINS 'Password'")
    private WebElement deleteDevicePasswordField;

    @iOSXCUITFindBy(accessibility = "Wrong password")
    private WebElement wrongPasswordDialog;

    @iOSXCUITFindBy(accessibility = "OK")
    private WebElement oKButton;

    private static final Function<String, By> predicateDeleteDeviceButtonByName = deviceName ->
            MobileBy.iOSNsPredicateString(String.format("type == 'XCUIElementTypeButton' AND label CONTAINS 'Remove %s'",
                    deviceName));

    private static final Function<String, By> predicateDeleteDeviceButtonByID = deviceID ->
        MobileBy.iOSNsPredicateString(String.format("name == 'device proteus ID' AND label CONTAINS '%s'",
            deviceID));

    private static final Function<String, By> predicateDeviceListEntry = device -> MobileBy.iOSNsPredicateString(
            String.format("name == 'device name' AND value CONTAINS '%s'", device));

    private final Function<Integer, By> xpathDevicesByCount = count ->
            By.xpath(String.format("//XCUIElementTypeTable[count(XCUIElementTypeCell)=%s]", count));

    private final Function<Integer, String> classChainDeviceForIndex =
        idx -> String.format("**/XCUIElementTypeStaticText[`name == \"device proteus ID\"`][%s]", idx);

    public UserSettingsDevicesPage(WebDriver driver) {
        super(driver);
    }

    public void tapDeleteDeviceButton(String deviceName) {
        final By locator = predicateDeleteDeviceButtonByName.apply(deviceName);
        getElement(locator).click();
    }

    public void tapDeleteButton() {
        deleteButton.click();
        if (!isElementInvisible(deleteButton)) {
            deleteButton.click();
        }
    }

    public void typePasswordToConfirmDeleteDevice(String password) {
        deleteDevicePasswordField.sendKeys(password);
    }

    public boolean isDeviceVisibleInList(String device) {
        final By locator = predicateDeviceListEntry.apply(device);
        return isLocatorDisplayed(locator);
    }

    public boolean isDeviceInvisibleInList(String device) {
        final By locator = predicateDeviceListEntry.apply(device);
        return isLocatorInvisible(locator);
    }

    public boolean isUserDevicesCountEqualTo(int expectedCount) {
        final By locator = xpathDevicesByCount.apply(expectedCount);
        return isLocatorDisplayed(locator);
    }

    public String getCurrentDeviceID() {
        return deviceID.getAttribute("value");
    }

    public void openDeviceDetailsPage(int deviceIndex) {
        final By locator = AppiumBy.iOSClassChain(classChainDeviceForIndex.apply(deviceIndex));
        getDriver().findElement(locator).click();
    }

    public boolean isWrongPasswordDialogVisible() {
        return waitUntilElementVisible(wrongPasswordDialog);
    }

    public void tapOKOnWrongPasswordDialog() {
        oKButton.click();
    }

    public void openDeviceDetailsPageById(String deviceId) {
        final By locator = predicateDeleteDeviceButtonByID.apply(deviceId);
        getDriver().findElement(locator).click();
    }
}
