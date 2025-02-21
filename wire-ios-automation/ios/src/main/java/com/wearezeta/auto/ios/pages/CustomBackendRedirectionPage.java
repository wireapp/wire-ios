package com.wearezeta.auto.ios.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class CustomBackendRedirectionPage extends IOSPage {

    public CustomBackendRedirectionPage(WebDriver driver) {
        super(driver);
    }

    @iOSXCUITFindBy(accessibility = "Redirecting...")
    private WebElement leavingWire;

    @iOSXCUITFindBy(accessibility = "ProgressView.Timer")
    private WebElement wireLogo;

    @iOSXCUITFindBy(accessibility = "Proceed")
    private WebElement proceedButton;

    @iOSXCUITFindBy(accessibility = "Redirect to an on-premises backend?")
    private WebElement redirectionTitle;

    public boolean isVisible() {
        return isElementVisible(wireLogo) && leavingWire.isDisplayed();
    }

    public void tapProceedButton() {
        proceedButton.click();
    }

    public boolean isRedirectionTitleVisible() {
        return redirectionTitle.isDisplayed();
    }

    public boolean isTextVisible(String text) {
        By locator = AppiumBy.accessibilityId(text);
        return waitUntilLocatorVisible(locator);
    }
}
