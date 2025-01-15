package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.*;

public class UniqueUsernameTakeoverPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Choose yours")
    private WebElement chooseYoursButton;

    @iOSXCUITFindBy(accessibility = "Keep this one")
    private WebElement keepThisOneButton;

    public UniqueUsernameTakeoverPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return waitUntilElementVisible(chooseYoursButton);
    }

    public void tapKeepThisOneButton() {
        keepThisOneButton.click();
    }
}