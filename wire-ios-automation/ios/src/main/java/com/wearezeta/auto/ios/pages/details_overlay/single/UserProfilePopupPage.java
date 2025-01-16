package com.wearezeta.auto.ios.pages.details_overlay.single;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class UserProfilePopupPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement xButton;

    @iOSXCUITFindBy(accessibility = "user image")
    private WebElement profilePicture;

    @iOSXCUITFindBy(accessibility = "username")
    private WebElement userNameLabel;

    @iOSXCUITFindBy(accessibility = "INFORMATION")
    private WebElement informationLabel;

    @iOSXCUITFindBy(accessibility = "DEVICES")
    private WebElement devicesTab;

    @iOSXCUITFindBy(accessibility = "right_button")
    private WebElement rightActionButton;

    @iOSXCUITFindBy(accessibility = "Guest")
    private WebElement guestLabel;

    private Function<String, By> predicateUsernameByValue = text ->
            MobileBy.iOSNsPredicateString(String.format("name == 'user_profile.name' AND label == '%s'", text));

    private Function<String, By> predicateUniqueUsernameByValue = text ->
            MobileBy.iOSNsPredicateString(String.format("name == 'username' AND label == '%s'", text));

    private static final String classChainInformationKey = "XCUIElementTypeStaticText[2]";
    private static final String classChainInformationValue = "XCUIElementTypeStaticText";

    private final Function<Integer, By> xpathInformationKeyByIndex =
            idx -> By.xpath(String.format("//XCUIElementTypeCell[%d]/%s", idx, classChainInformationKey));
    private final Function<Integer, By> xpathInformationValueByIndex =
            idx -> By.xpath(String.format("//XCUIElementTypeCell[%d]/%s", idx, classChainInformationValue));

    private Function<String, String> predicateStrInformationKeyValue = text ->
            String.format("label == '%s' AND value == '%s'", text, text);

    private static final String strLeftActionButton = "left_button";
    private static final String strOpenConversationButton = "Open conversation";
    private static final String strConnectButton = "CONNECT";
    private static final String strOpenSelfProfileButton = "Open Profile";
    private Function<String, By> predicateLeftButtonByLabel = text ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND label == '%s'", strLeftActionButton,text));


    public UserProfilePopupPage(WebDriver driver) {
        super(driver);
    }

    public void tapXButton() {
        xButton.click();
    }

    public void tapOpenConversationButton() {
        getElement(predicateLeftButtonByLabel.apply(strOpenConversationButton)).click();
    }

    public void tapSelfProfileButton() {
        getElement(predicateLeftButtonByLabel.apply(strOpenSelfProfileButton)).click();
    }

    public void tapMoreActionsButton() {
        rightActionButton.click();
    }

    public boolean isUserProfilePopupVisible() {
        return isElementVisible(userNameLabel) && xButton.isDisplayed();
    }

    public boolean isUserProfilePopupInvisible() {
        return isElementInvisible(userNameLabel) && isElementInvisible(xButton);
    }

    public boolean isUserNameVisible(String value) {
        return isLocatorDisplayed(predicateUsernameByValue.apply(value));
    }

    public boolean isUserNameInvisible(String value) { return isLocatorInvisible(predicateUsernameByValue.apply(value)); }

    public boolean isUniqueUserNameVisible(String value) {
        return isLocatorDisplayed(predicateUniqueUsernameByValue.apply(value));
    }

    public boolean isUniqueUserNameInvisible(String value) { return isLocatorInvisible(predicateUniqueUsernameByValue.apply(value)); }

    public boolean isUserProfilePictureVisible() {
        return isElementVisible(profilePicture);
    }

    public boolean isInformationLabelVisible() {
        return informationLabel.isDisplayed();
    }

    public boolean isInformationLabelInvisible() {
        return isElementInvisible(informationLabel);
    }

    public boolean isInformationKeyValuePairVisible(String key, String value, int index) {
        final By cellKeyLocator = xpathInformationKeyByIndex.apply(index);
        final By cellValueLocator = xpathInformationValueByIndex.apply(index);
        final By keyID = MobileBy.iOSNsPredicateString(predicateStrInformationKeyValue.apply(key));
        final By valueID = MobileBy.iOSNsPredicateString(predicateStrInformationKeyValue.apply(value));
        return isLocatorDisplayed(getElement(cellKeyLocator), keyID) && isLocatorDisplayed(getElement(cellValueLocator), valueID);
    }

    public boolean isMoreActionsButtonVisible() {
        return rightActionButton.isDisplayed();
    }

    public boolean isMoreActionsButtonInvisible() {
        return isElementInvisible(rightActionButton);
    }

    public boolean isOpenConversationButtonVisible() {
        return isLocatorDisplayed(predicateLeftButtonByLabel.apply(strOpenConversationButton));
    }

    public boolean isOpenConversationButtonInvisible() {
        return isLocatorInvisible(predicateLeftButtonByLabel.apply(strOpenConversationButton));
    }

    public boolean isConnectButtonVisible() {
        return isLocatorDisplayed(predicateLeftButtonByLabel.apply(strConnectButton));
    }

    public boolean isConnectButtonInvisible() {
        return isLocatorInvisible(predicateLeftButtonByLabel.apply(strConnectButton));
    }

    public boolean isDevicesTabInvisible() {
        return isElementInvisible(devicesTab);
    }

    public boolean isGuestLabelVisible() {
        return guestLabel.isDisplayed();
    }

    public boolean isGuestLabelInvisible() {
        return isElementInvisible(guestLabel);
    }
}
