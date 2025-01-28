package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class MessageDetailsPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Close")
    private WebElement closeButton;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND name == 'Tab0' AND label CONTAINS 'Read'")
    private WebElement readTabActive;

    private static final Function<String, String> predicateStrUserByName = name ->
            String.format("name == 'user_cell.name' AND value CONTAINS '%s'", name);

    public MessageDetailsPage(WebDriver driver) {
        super(driver);
    }

    public boolean isContactVisible(String name) {
        return waitUntilLocatorVisible(MobileBy.iOSNsPredicateString(predicateStrUserByName.apply(name)));
    }

    public void tapCloseButton() {
        closeButton.click();
    }

    public boolean isContactVisibleInSeenTab(String name) {
        return isContactVisible(name) && readTabActive.isDisplayed();
    }
}
