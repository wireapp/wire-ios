package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class TeamSearchUIPage extends SearchUIPage {

    @iOSXCUITFindBy(accessibility = "Services")
    private WebElement servicesTabButton;

    public TeamSearchUIPage(WebDriver driver) {
        super(driver);
    }

    public void tapTeamSearchUITab() {
        servicesTabButton.click();
    }
}
