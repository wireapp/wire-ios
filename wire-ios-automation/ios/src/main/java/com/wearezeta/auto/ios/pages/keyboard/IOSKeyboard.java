package com.wearezeta.auto.ios.pages.keyboard;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import org.openqa.selenium.WebDriver;

public class IOSKeyboard extends IOSPage {
    private static final By classKeyboard = By.className("XCUIElementTypeKeyboard");
    private static final By predicateCommitButton = MobileBy.iOSNsPredicateString(
            "name IN[c] {'Go', 'Send', 'Done', 'Return'}"
    );

    private static final By nameSpaceButton = MobileBy.AccessibilityId("space");
    private static final By nameNextButton = MobileBy.AccessibilityId("Next:");

    private static final By nameHideKeyboardButton = MobileBy.AccessibilityId("Hide keyboard");

    private static final By nameKeyboardDeleteButton = MobileBy.AccessibilityId("delete");

    private static final Timedelta DEFAULT_VISIBILITY_TIMEOUT = Timedelta.ofSeconds(5);

    public IOSKeyboard(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible(Timedelta timeout) {
        return isLocatorDisplayed(nameSpaceButton, timeout);
    }

    public boolean isInvisible(Timedelta timeout) {
        return isLocatorInvisible(nameSpaceButton, timeout);
    }

    public boolean isVisible() {
        return isVisible(DEFAULT_VISIBILITY_TIMEOUT);
    }

    public boolean isInvisible() {
        return isInvisible(DEFAULT_VISIBILITY_TIMEOUT);
    }

    public void pressSpaceButton() {
        getElement(nameSpaceButton).click();
    }

    public void pressNextButton() {
        getElement(nameNextButton).click();
    }

    public void pressHideButton() {
        getElement(nameHideKeyboardButton).click();
    }

    public void pressCommitButton() {
        getElement(classKeyboard)
                .findElement(predicateCommitButton)
                .click();
    }
}
