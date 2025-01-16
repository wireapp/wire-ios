package com.wearezeta.auto.ios.pages.details_overlay.single;

import java.util.function.Function;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class SingleConnectedUserProfilePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Devices")
    private WebElement devicesTab;

    @iOSXCUITFindBy(accessibility = "INFORMATION")
    private WebElement informationLabel;

    @iOSXCUITFindBy(accessibility = "cell.profile.group_admin_options")
    private WebElement adminToggle;

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    @iOSXCUITFindBy(accessibility = "Back")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "Go back to conversation details")
    private WebElement goBacktoButton;

    @iOSXCUITFindBy(accessibility = "left_button")
    private WebElement leftActionButton;

    @iOSXCUITFindBy(accessibility = "right_button")
    private WebElement rightActionButton;

    @iOSXCUITFindBy(accessibility = "ReadReceiptsStatusFooter")
    private WebElement readReceiptStatusFooter;

    @iOSXCUITFindBy(accessibility = "Start conversation")
    private WebElement startConversation;

    private final Function<Integer, By> xpathInformationKeyByIndex =
            idx -> By.xpath(String.format("//XCUIElementTypeCell[%d]/XCUIElementTypeStaticText[2]", idx));
    private final Function<Integer, By> xpathInformationValueByIndex =
            idx -> By.xpath(String.format("//XCUIElementTypeCell[%d]/XCUIElementTypeStaticText", idx));

    private Function<String, String> predicateStrInformationKeyValue = text ->
            String.format("label == '%s' AND value == '%s'", text, text);

    public SingleConnectedUserProfilePage(WebDriver driver) {
        super(driver);
    }

    public void tapBackButton() {
        if (isElementVisible(goBacktoButton)) {
            goBacktoButton.click();
        } else {
            backButton.click();
        }
    }

    public boolean isInformationLabelVisible() {
        return informationLabel.isDisplayed();
    }

    public boolean isInformationLabelInvisible() {
        return waitUntilElementInvisible(informationLabel);
    }

    public boolean isAdminToggleVisible() {
        return isElementVisible(adminToggle);
    }

    public boolean isInformationKeyValuePairVisible(String key, String value, int index) {
        if (isAdminToggleVisible()) {
            index++;
        }
        final By cellKeyLocator = xpathInformationKeyByIndex.apply(index);
        final By cellValueLocator = xpathInformationValueByIndex.apply(index);
        final By keyID = MobileBy.iOSNsPredicateString(predicateStrInformationKeyValue.apply(key));
        final By valueID = MobileBy.iOSNsPredicateString(predicateStrInformationKeyValue.apply(value));
        return isLocatorDisplayed(getElement(cellKeyLocator), keyID) && isLocatorDisplayed(getElement(cellValueLocator), valueID);
    }

    public boolean isReadReceiptFooterVisible() {
        return waitUntilElementVisible(readReceiptStatusFooter);
    }

    public void switchToDevicesTab() {
        devicesTab.click();
    }

    public void tapXButton() {
        closeButton.click();
    }

    public void tapCreateGroupButton() {
        leftActionButton.click();
    }

    public void tapOpenMenuButton() {
        rightActionButton.click();
    }

    public void tapStartConversation() {
        startConversation.click();
    }

}
