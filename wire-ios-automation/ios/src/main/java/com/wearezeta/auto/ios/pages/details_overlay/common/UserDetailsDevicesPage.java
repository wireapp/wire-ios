package com.wearezeta.auto.ios.pages.details_overlay.common;

import com.wearezeta.auto.ios.pages.IOSPage;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import java.util.function.Function;

public class UserDetailsDevicesPage extends IOSPage {

    private static final String xpathStrDevicesRoot =
            "//XCUIElementTypeButton[@label='Devices']/following::XCUIElementTypeCollectionView";

    private static final By predicateStrDevideTitleValue = MobileBy.iOSNsPredicateString("name == 'device_cell.name' AND value == 'Legal Hold'");

    private static final By nameLegalHoldIcon = MobileBy.AccessibilityId("img.device_class.legalhold");
    private final String notVerifiedLabel = "Not Verified";

    private final Function<Integer, By> classChainGetDeviceCellByNumber = (deviceNumber) -> MobileBy.iOSClassChain(String.format("**/XCUIElementTypeCollectionView[`visible == 1`]/XCUIElementTypeCell[%s]", deviceNumber));

    private final Function<Integer, By> xpathDeviceByIndex =
            idx -> By.xpath(String.format("%s/XCUIElementTypeCell[%s]", getDevicesListRootXPath(), idx));

    private final Function<Integer, By> xpathDevicesByCount = count ->
            By.xpath(String.format("//XCUIElementTypeCollectionView[count(XCUIElementTypeCell)=%s]", count));

    public UserDetailsDevicesPage(WebDriver driver) {
        super(driver);
    }

    protected String getDevicesListRootXPath() {
        return xpathStrDevicesRoot;
    }

    public void openDeviceDetailsPage(int deviceIndex) {
        final By locator = xpathDeviceByIndex.apply(deviceIndex);
        getElement(locator).click();
    }

    public boolean isParticipantDevicesCountEqualTo(int expectedCount) {
        final By locator = xpathDevicesByCount.apply(expectedCount);
        return isLocatorDisplayed(locator);
    }

    public boolean isLegalHoldTheFirstDevice() {
        final By cellIndexLocator = xpathDeviceByIndex.apply(2);
        return isLocatorDisplayed(getElement(cellIndexLocator), predicateStrDevideTitleValue) && isLocatorExist(nameLegalHoldIcon);
    }

    public boolean isDeviceNumberNotVerified(int number) {
        number++;
        return getElement(classChainGetDeviceCellByNumber.apply(number)).getAttribute("label").contains(notVerifiedLabel);
    }

    public boolean isDeviceNumberVerified(int number) {
        number++;
        return !getElement(classChainGetDeviceCellByNumber.apply(number)).getAttribute("label").contains(notVerifiedLabel);
    }
}
