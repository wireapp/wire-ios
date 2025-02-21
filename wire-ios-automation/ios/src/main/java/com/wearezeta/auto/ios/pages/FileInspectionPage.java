package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class FileInspectionPage extends IOSPage {

    public FileInspectionPage(WebDriver driver) {
        super(driver);
    }

    @iOSXCUITFindBy(accessibility = "QLOverlayDefaultActionButtonAccessibilityIdentifier")
    private WebElement shareButton;

    @iOSXCUITFindBy(accessibility = "QLOverlayDoneButtonAccessibilityIdentifier")
    private WebElement doneButton;

    public void tapShareButton() {
        shareButton.click();
    }

    public void tapDoneButton() {
        doneButton.click();
    }
}
