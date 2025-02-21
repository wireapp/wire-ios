package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class CustomBackendWelcomePage extends IOSPage {
    
    @iOSXCUITFindBy(accessibility = "Login")
    private WebElement emailLoginButton;

    private static final Function<String, By> predicateWelcomeToBackend = backendName -> MobileBy.iOSNsPredicateString(String.format("label CONTAINS '%s'", backendName));

    public CustomBackendWelcomePage(WebDriver driver) {
        super(driver);
    }

    public boolean isTextVisible(String backendName) {
        return isLocatorDisplayed(predicateWelcomeToBackend.apply(backendName));
    }

    public boolean isConnectionMessageVisible(String backendName) {
        return isLocatorDisplayed(predicateWelcomeToBackend.apply(backendName));
    }

    public void tapOnLoginWithEmailButton() {
        waitUntilElementClickable(emailLoginButton);
        emailLoginButton.click();
    }
}
