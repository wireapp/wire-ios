package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class PasteDialog extends IOSPage {

    @iOSXCUITFindBy(accessibility = "OK")
    private WebElement oKButton;

    public PasteDialog(WebDriver driver) {
        super(driver);
    }

    public void tapOKButton() {
        oKButton.click();
    }
}
