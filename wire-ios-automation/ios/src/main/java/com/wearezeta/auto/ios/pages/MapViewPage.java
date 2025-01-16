package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class MapViewPage extends  IOSPage{

    @iOSXCUITFindBy(accessibility = "sendLocation")
    private WebElement sendLocationButton;

    public MapViewPage(WebDriver driver) {
        super(driver);
    }

    public void clickSendLocationButton() {
        sendLocationButton.click();
    }
}
