package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class BackupPasswordOverlayPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "password input")
    private WebElement passwordInput;

    @iOSXCUITFindBy(accessibility = "Next")
    private WebElement nextButton;

    public BackupPasswordOverlayPage(WebDriver driver) {
        super(driver);
    }

    public void typePassword(String password) {
        passwordInput.clear();
        passwordInput.sendKeys(password);
    }

    public void tapNextButton() {
        nextButton.click();
    }
}
