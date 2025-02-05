package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class ForwardPage extends IOSPage {

    public ForwardPage(WebDriver driver) {
        super(driver);
    }

    @iOSXCUITFindBy(accessibility = "shield icon")
    private WebElement shieldIcon;

    @iOSXCUITFindBy(accessibility = "legalHoldIcon")
    private WebElement legalHoldIcon;

    @iOSXCUITFindBy(accessibility = "guestUserIcon")
    private WebElement guestUserIcon;

    @iOSXCUITFindBy(accessibility = "img.external")
    private WebElement externalIcon;

    @iOSXCUITFindBy(accessibility = "send")
    private WebElement sendButton;

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    private static final Function<String, By> conversationLocatorByName = name -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeOther[$name == 'textViewSearch'$]" +
                            "/**/XCUIElementTypeCell[$type == 'XCUIElementTypeStaticText' AND name == '%s'$]",
                    name));

    public void selectConversation(String name) {
        getElement(conversationLocatorByName.apply(name)).click();
    }

    public void tapSendButton() {
        sendButton.click();
    }

    public void tapCloseButton() {
        closeButton.click();
    }

    public boolean isConversationVisible(String name) {
        return getDriver().findElement(conversationLocatorByName.apply(name)).isDisplayed();
    }

    public boolean isConversationInvisible(String name) {
        return isLocatorInvisible(conversationLocatorByName.apply(name));
    }

    public boolean isShieldIconVisible() {
        return shieldIcon.isDisplayed();
    }

    public boolean isShieldIconInvisible() {
        return isElementInvisible(shieldIcon);
    }

    public boolean isLegalHoldIndicatorVisible() {
        return legalHoldIcon.isDisplayed();
    }

    public boolean isLegalHoldIndicatorInvisible() {
        return isElementInvisible(legalHoldIcon);
    }

    public boolean isGuestIconVisible() {
        return guestUserIcon.isDisplayed();
    }

    public boolean isGuestIconInvisible() {
        return isElementInvisible(guestUserIcon);
    }

    public boolean isExternalIconVisible() {
        return externalIcon.isDisplayed();
    }

    public boolean isExternalIconInvisible() {
        return isElementInvisible(externalIcon);
    }
}
