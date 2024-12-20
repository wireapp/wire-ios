package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class ArchivePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "archiveCloseButton")
    private WebElement closeArchiveButton;

    private static final String strNameConversation = "title";

    private static final Function<String, By> predicateStrConversationByLabel = text ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND label == '%s'", strNameConversation, text));

    public ArchivePage(WebDriver driver) {
        super(driver);
    }

    public void clickCloseArchivePageButton() {
        closeArchiveButton.click();
    }

    public boolean isConversationInList(String name) {
        final By locator = predicateStrConversationByLabel.apply(name);
        return isLocatorDisplayed(locator, Timedelta.ofSeconds(5));
    }

    public boolean isConversationNotInList(String name) {
        final By locator = predicateStrConversationByLabel.apply(name);
        return isLocatorInvisible(locator, Timedelta.ofSeconds(5));
    }

    public void tapConversationsListItem(String name) {
        final By locator = predicateStrConversationByLabel.apply(name);
        getElement(locator).click();
    }
}
