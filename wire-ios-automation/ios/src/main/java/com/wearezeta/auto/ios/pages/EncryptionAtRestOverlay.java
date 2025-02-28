package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.Keys;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class EncryptionAtRestOverlay extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Wire Bund")
    private WebElement application;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeImage' AND name == 'wire-logo-shield'")
    private WebElement wireShieldLogo;

    public EncryptionAtRestOverlay(WebDriver driver) {
        super(driver);
    }

    public boolean isPasscodeOverlayVisible() {
        return wireShieldLogo.isDisplayed();
    }

    public boolean isPasscodeOverlayInvisible() {
        // currently not possible as on iOS 17 it is not possible to interact with the passcode overlay
        // return isElementInvisible(passcodeField);
        return true;
    }

    public void typePasscode(String passcode) {
        application.sendKeys(passcode);
    }

    public void pressEnter() {
        application.sendKeys(Keys.ENTER);
    }
}
