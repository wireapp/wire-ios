package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class GuestOptionsPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Go back to conversation details")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "Create Link")
    private WebElement createLinkButton;

    @iOSXCUITFindBy(accessibility = "Create link without password")
    private WebElement linkWithoutPassword;

    @iOSXCUITFindBy(accessibility = "Create password secured link")
    private WebElement linkWithPassword;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Copy Link\"`]")
    private WebElement copyLink;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Share Link\"`]")
    private WebElement shareLink;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Revoke Link…\"`]")
    private WebElement revokeLink;

    private static final Function<String, By> predicateStrAllowGuestsByValue = text ->
            MobileBy.iOSNsPredicateString(String.format("name == 'toggle.guestoptions.allowguests' AND value == '%s'", text));

    public GuestOptionsPage(WebDriver driver) {
        super(driver);
    }

    public void tapBackButton() {
        backButton.click();
    }

    public boolean isCreateLinkButtonVisible() {
        return createLinkButton.isDisplayed();
    }

    public boolean isCreateLinkButtonInvisible() {
        return isElementInvisible(createLinkButton);
    }

    public boolean isAllowGuestsEqualsTo(String expectedValue) {
        final By locator = predicateStrAllowGuestsByValue.apply(expectedValue);
        return isLocatorDisplayed(locator);
    }

    public void createLink() {
        createLinkButton.click();
    }

    public void createLinkWithoutPassword() {
        createLink();
        linkWithoutPassword.click();
    }

    public void copyLink() {
        copyLink.click();
    }
}
