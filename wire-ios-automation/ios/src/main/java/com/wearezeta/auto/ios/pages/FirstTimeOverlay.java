package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class FirstTimeOverlay extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'It’s the first time you’re using Wire on this device.'")
    private WebElement heading;

    @iOSXCUITFindBy(accessibility = "ignore_backup")
    private WebElement oKButton;

    @iOSXCUITFindBy(accessibility = "restore_backup")
    private WebElement restoreButton;

    public FirstTimeOverlay(WebDriver driver) {
        super(driver);
    }

    public boolean isHeadingVisible() {
        return waitUntilElementVisible(heading);
    }

    public boolean waitUntilVisible() {
        return waitUntilElementVisible(restoreButton);
    }

    public boolean waitUntilInvisible() {
        return waitUntilElementInvisible(restoreButton);
    }

    public void accept() {
        waitUntilElementClickable(oKButton);
        oKButton.click();
    }

    public void tapRestoreButton() {
        waitUntilElementClickable(restoreButton);
        restoreButton.click();
    }
}