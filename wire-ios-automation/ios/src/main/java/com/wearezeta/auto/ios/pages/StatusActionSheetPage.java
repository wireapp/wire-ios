package com.wearezeta.auto.ios.pages;

import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;

public class StatusActionSheetPage extends IOSPage {
    public StatusActionSheetPage(WebDriver driver) {
        super(driver);
    }

    public void tapStatusName(String name) {
        getElement(MobileBy.AccessibilityId(name)).click();
    }
}
