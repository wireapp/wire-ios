package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class GroupPendingParticipantOutgoingConnectionPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Go back to conversation details")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "right_button")
    private WebElement openMenuButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[`label == 'Connect'`][-1]")
    private WebElement connectButton;


    private static final Function<String, By> predicateNameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value == '%s'",
                    name));

    public GroupPendingParticipantOutgoingConnectionPage(WebDriver driver) {
        super(driver);
    }

    public void tapBackButton() {
        backButton.click();
    }

    public void tapOpenMenuButton() {
        openMenuButton.click();
    }

    public boolean isUserNameVisible(String value) {
        return isLocatorDisplayed(predicateNameByValue.apply(value));
    }

    public boolean isConnectButtonVisible() {
        return connectButton.isDisplayed();
    }
}
