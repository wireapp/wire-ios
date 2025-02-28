package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class AdvancedSettingsPage extends IOSPage {
    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Version Technical Details\"`]")
    private WebElement versionTechnicalDetailsMenu;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND value CONTAINS \"core-crypto\"")
    private WebElement versionDetails;

    public AdvancedSettingsPage(WebDriver driver) {
        super(driver);
    }


    public void openVersionTechnicalDetails() {
        versionTechnicalDetailsMenu.click();
    }

    public boolean isVersionDetailsVisible() {
        return versionDetails.isDisplayed();
    }
}
