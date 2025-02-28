package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class PollMessagesPage extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND value=='selected'")
    private WebElement anySelectedPollButton;

    private static final Function<String, By> pollMessageText = text ->
            MobileBy.iOSNsPredicateString(String.format("name == 'Message' AND value CONTAINS '%s'", text));

    private static final Function<String, By> confirmedPollButtonByText = text ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND value=='confirmed'", text));

    private static final Function<String, By> unselectedPollButtonByText = text ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND value=='unselected'", text));

    private static final Function<String, By> selectedPollButtonByText = text ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND value=='selected'", text));

    public PollMessagesPage(WebDriver driver) {
        super(driver);
    }

    public boolean isPollMessageTextContains(String text) {
        return waitUntilLocatorVisible(pollMessageText.apply(text));
    }

    public boolean areAllPollButtonsUnselected() {
        return waitUntilElementInvisible(anySelectedPollButton);
    }

    public void tapPollButtonWithTheText(String text) {
        getDriver().findElement(MobileBy.AccessibilityId(text.toUpperCase())).click();
    }

    public boolean isPollButtonWithTextConfirmed(String buttonText) {
        return waitUntilLocatorVisible(confirmedPollButtonByText.apply(buttonText.toUpperCase()));
    }

    public boolean isPollButtonWithTextUnselected(String buttonText) {
        return waitUntilLocatorVisible(unselectedPollButtonByText.apply(buttonText.toUpperCase()));
    }

    public boolean isPollButtonWithTextSelected(String buttonText) {
        return waitUntilLocatorVisible(selectedPollButtonByText.apply(buttonText.toUpperCase()));
    }

    public boolean isPollErrorMessageVisible(String error) {
        return waitUntilLocatorVisible(MobileBy.AccessibilityId(error));
    }

    public boolean isPollErrorMessageInvisible(String error) {
        return isLocatorInvisible(MobileBy.AccessibilityId(error));
    }
}
