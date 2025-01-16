package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class ActionsSheetPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeSheet/**/XCUIElementTypeButton[`visible == 1 AND label != ''`][-1]")
    private WebElement declineActionButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[`visible == 1 AND label != ''`]")
    private WebElement confirmActionButton;

    private static final Function<String, By> predicateNewActionButtonByName = text ->
            MobileBy.iOSNsPredicateString(String.format("type == 'XCUIElementTypeButton' AND label == '%s'", text));

    private static final Function<String, String> predicateActionSheetLabelByText = text ->
            String.format("type == 'XCUIElementTypeStaticText' AND label CONTAINS '%s'", text);

    public ActionsSheetPage(WebDriver driver) {
        super(driver);
    }

    private By getButtonLocatorByName(String name) {
        return predicateNewActionButtonByName.apply(name);
    }

    public void tapMenuItem(String name) {
        getDriver().findElement(getButtonLocatorByName(name)).click();
    }

    public boolean isItemVisible(String name) {
        return getDriver().findElement(getButtonLocatorByName(name)).isDisplayed();
    }

    public boolean isItemInvisible(String name) {
        return isLocatorInvisible(getButtonLocatorByName(name));
    }

    public boolean isActionSheetContainsText(String text) {
        return getDriver().findElement(MobileBy.iOSNsPredicateString(predicateActionSheetLabelByText.apply(text)))
                .isDisplayed();
    }

    public boolean isActionSheetDoesNotContainsText(String text) {
        return isLocatorInvisible(MobileBy.iOSNsPredicateString(predicateActionSheetLabelByText.apply(text)));
    }

    public void confirm() {
        confirmActionButton.click();
    }

    public void decline() {
        declineActionButton.click();
    }
}
