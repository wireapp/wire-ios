package com.wearezeta.auto.ios.pages.details_overlay.single;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class SelfProfilePage extends IOSPage {
/**
   @iOSXCUITFindBy(iOSNsPredicate = "label == 'Settings' AND name == 'Settings' AND type == 'XCUIElementTypeStaticText'")
    WebElement settingsButton;
 */

    @iOSXCUITFindBy(accessibility = "user image")
    private WebElement profilePicture;

    @iOSXCUITFindBy(accessibility = "Add Account")
    private WebElement addAccountButton;

    @iOSXCUITFindBy(accessibility = "Manage Team")
    private WebElement manageTeamButton;

    @iOSXCUITFindBy(accessibility = "Name")
    private WebElement setStatusButton;

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement profileCloseButton;

    public SelfProfilePage(WebDriver driver) {
        super(driver);
    }

    public void tapProfilePicture() {
        profilePicture.click();
    }

    public void tapSetStatusButton() {
        setStatusButton.click();
    }

    public void tapProfileCloseButton() {
        profileCloseButton.click();
    }

    private static final Function<String, By> predicateNameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value == '%s'",
                    name));

    private static final Function<String, By> predicateABNameByName = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name == 'correlation' AND value='%s'",
                    name.trim().length() > 0 ? (name + " in Contacts") : "in Contacts"));

    private static final Function<String, By> predicateUniqueUsernameByUsername = username -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.username', 'username', 'handle'} AND value == '%s'",
                    username.startsWith("@") ? username : ("@" + username)));

    private static final Function<String, By> predicateSSONameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value CONTAINS '%s'",
                    name));

    private static final Function<String, By> predicateTeamName = name -> MobileBy.iOSNsPredicateString(
            String.format("label == 'Team name' AND value == '%s'", name));

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

    public boolean isUserDetailVisible(String detailName, String value) {
        final By locator = getUserDetailLocator(detailName, value);
        return isLocatorDisplayed(locator);
    }

    public boolean isUserDetailInvisible(String detailName, String value) {
        final By locator = getUserDetailLocator(detailName, value);
        return isLocatorInvisible(locator);
    }

    public void tapAddAccountButton() {
        waitUntilElementClickable(addAccountButton);
        addAccountButton.click();
    }

    public void tapManageTeam() {
        waitUntilElementClickable(manageTeamButton);
        manageTeamButton.click();
    }
/**
    public void tapSettingsButton() {
        waitUntilElementClickable(settingsButton);
        settingsButton.click();
    }
 */
}
