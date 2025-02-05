package com.wearezeta.auto.ios.pages.details_overlay.single;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class SinglePendingUserIncomingConnectionProfilePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Connect")
    private WebElement connectButton;

    @iOSXCUITFindBy(accessibility = "IGNORE")
    private WebElement ignoreButton;

    @iOSXCUITFindBy(accessibility = "Go back to conversation details")
    private WebElement backButton;

    private Function<String, By> predicateDisplayName = text ->
            MobileBy.iOSNsPredicateString(String.format("label == '%s'", text));

    public SinglePendingUserIncomingConnectionProfilePage(WebDriver driver) {
        super(driver);
    }

    public void tapConnect() {
        connectButton.click();
    }

    public void tapIgnoreInboxStyleButton() {
        ignoreButton.click();
    }

    public void tapBackButton() {
        backButton.click();
    }

    public boolean isDisplayNameVisible(String value) {
        return isLocatorDisplayed(predicateDisplayName.apply(value));
    }

    public boolean isDisplayNameInvisible(String value) {
        return isLocatorInvisible(predicateDisplayName.apply(value));
    }
}
