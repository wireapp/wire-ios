package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class ServiceCreationPage extends IOSPage {
    public ServiceCreationPage(WebDriver driver) {
        super(driver);
    }

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    public void tapCloseButton() {
        closeButton.click();
    }
}
