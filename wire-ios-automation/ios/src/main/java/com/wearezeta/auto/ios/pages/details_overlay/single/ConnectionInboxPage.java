package com.wearezeta.auto.ios.pages.details_overlay.single;

import java.util.function.Function;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class ConnectionInboxPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[`name ==[c] 'ignore'`][-1]")
    private WebElement ignoreButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[`name == 'accept' OR name == 'CONNECT'`][-1]")
    private WebElement connectButton;

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

    public ConnectionInboxPage(WebDriver driver) {
        super(driver);
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

    public void tapIgnoreButton() {
        ignoreButton.click();
    }

    public void tapConnectButton() {
        connectButton.click();
    }

    public boolean isConnectButtonVisible() {
        return waitUntilElementVisible(connectButton);
    }
}
