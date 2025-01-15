package com.wearezeta.auto.ios.pages.details_overlay.single;

import java.util.function.Function;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import org.openqa.selenium.WebDriver;

public class SinglePendingUserOutgoingConnectionPage extends IOSPage {

    private static final By nameCancelRequest = MobileBy.AccessibilityId("Cancel Request");
    private static final By nameBackButton = MobileBy.AccessibilityId("ConversationBackButton");
    private static final By nameBackButtoniPad = MobileBy.AccessibilityId("Go back to conversation details");
    protected static final By classChainConnectOtherUserButton =
            MobileBy.iOSClassChain("**/XCUIElementTypeStaticText[`label == 'Connect'`]");

    protected static final By nameArchiveRequestButton = MobileBy.AccessibilityId("archive connection");

    protected static final By classChainCancelRequestButton = MobileBy.iOSClassChain(
            "**/XCUIElementTypeStaticText[`label == 'Cancel Request' OR name == 'cancel connection'`][-1]");

    public void tapBackButton() {
        getElement(nameBackButton).click();
    }

    public void tapBackButtoniPad() {
        getElement(nameBackButtoniPad).click();
    }

    protected static final By nameXButton = MobileBy.AccessibilityId("close");

    private static final Function<String, By> predicateNameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value == '%s'",
                    name));
    private static final By predicateName = MobileBy.iOSNsPredicateString(
            "type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'}");

    private static final Function<String, By> predicateABNameByName = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name == 'correlation' AND value='%s'",
                    name.trim().length() > 0 ? (name + " in Contacts") : "in Contacts"));
    private static final By nameABName = MobileBy.AccessibilityId("correlation");

    private static final Function<String, By> predicateUniqueUsernameByUsername = username -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.username', 'username', 'handle'} AND value == '%s'",
                    username.startsWith("@") ? username : ("@" + username)));
    private static final By predicateUniqueUsername = MobileBy.iOSNsPredicateString(
            "type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.username', 'username', 'handle'}");

    private static final Function<String, By> predicateSSONameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value CONTAINS '%s'",
                    name));

    private static final By nameTeamName = MobileBy.AccessibilityId("team name");
    private static final Function<String, By> predicateTeamName = name -> MobileBy.iOSNsPredicateString(
            String.format("name == 'team name' AND value == '%s'", name.toUpperCase()));

    public SinglePendingUserOutgoingConnectionPage(WebDriver driver) {
        super(driver);
    }

    protected By getButtonLocatorByName(String name) {
        switch (name.toLowerCase()) {
            case "archive":
                return nameArchiveRequestButton;
            case "connect":
                return classChainConnectOtherUserButton;
            case "cancel request":
                return classChainCancelRequestButton;
            case "x":
                return nameXButton;
            default:
                throw new IllegalArgumentException(String.format("Unknown button name '%s'", name));
        }
    }

    protected By getUserDetailLocator(String detailName, String expectedValue) {
        switch (detailName.toLowerCase()) {
            case "name":
                return predicateNameByValue.apply(expectedValue);
            case "unique username":
                return predicateUniqueUsernameByUsername.apply(expectedValue);
            case "address book name":
                return predicateABNameByName.apply(expectedValue);
            case "team name":
                return predicateTeamName.apply(expectedValue);
            case "sso username":
                return predicateSSONameByValue.apply(expectedValue);
            default:
                throw new IllegalArgumentException(String.format("Unknown user detail name '%s'", detailName));
        }
    }

    private By getUserDetailLocator(String detailName) {
        switch (detailName.toLowerCase()) {
            case "name":
                return predicateName;
            case "unique username":
                return predicateUniqueUsername;
            case "address book name":
                return nameABName;
            case "team name":
                return nameTeamName;
            case "create group button":
                return nameTeamName;
            default:
                throw new IllegalArgumentException(String.format("Unknown user detail name '%s'", detailName));
        }
    }

    public boolean isUserDetailVisible(String detailName, String value) {
        final By locator = getUserDetailLocator(detailName, value);
        return isLocatorDisplayed(locator);
    }

    public boolean isUserDetailInvisible(String detailName, String value) {
        final By locator = getUserDetailLocator(detailName, value);
        return isLocatorInvisible(locator);
    }

    public boolean isUserDetailVisible(String detailName) {
        final By locator = getUserDetailLocator(detailName);
        return isLocatorDisplayed(locator);
    }

    public boolean isUserDetailInvisible(String detailName) {
        final By locator = getUserDetailLocator(detailName);
        return isLocatorInvisible(locator);
    }

    public void tapButton(String name) {
        final By locator = getButtonLocatorByName(name);
        getElement(locator).click();
    }

    public boolean isButtonVisible(String name) {
        final By locator = getButtonLocatorByName(name);
        return isLocatorDisplayed(locator);
    }

    public boolean isButtonInvisible(String name) {
        final By locator = getButtonLocatorByName(name);
        return isLocatorInvisible(locator);
    }

    public boolean isCancelRequestButtonVisible() {
        return isLocatorDisplayed(nameCancelRequest);
    }

    public boolean isCancelRequestButtonInvisible() {
        return isLocatorInvisible(nameCancelRequest);
    }
}
