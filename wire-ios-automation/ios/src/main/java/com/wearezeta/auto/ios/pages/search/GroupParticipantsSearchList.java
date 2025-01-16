package com.wearezeta.auto.ios.pages.search;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.*;

import java.util.function.Function;

public class GroupParticipantsSearchList extends IOSPage {
    private static final String classChainStrViewRoot = "**/XCUIElementTypeCollectionView[`name == 'add_participants.list'`]";

    public GroupParticipantsSearchList(WebDriver driver) {
        super(driver);
    }

    private static final String nameStrSearchInput = "textViewSearch";

    private static final By predicateSearchInput = MobileBy.iOSNsPredicateString(isTablet() ?
            String.format("type == 'XCUIElementTypeTextView' AND name == '%s' AND visible == 1", nameStrSearchInput) :
            String.format("type == 'XCUIElementTypeTextView' AND name == '%s'", nameStrSearchInput));

    private static final By nameNoResults = MobileBy.AccessibilityId("button.searchui.open-services-no-results");

    private static final By predicateEveryoneIsHere =
            MobileBy.iOSNsPredicateString("value BEGINSWITH 'Everyone' AND value ENDSWITH 'here.'");

    private static final String nameStrItemName = "user_cell.name";

    private final Function<String, String> classChainStrItemCellByName = name ->
            String.format("%s/XCUIElementTypeCell[$name == '%s' AND value == '%s'$]",
                    classChainStrViewRoot, nameStrItemName, name);

    final Function<String, By> classChainItemCellByName = name -> MobileBy.iOSClassChain(
            classChainStrItemCellByName.apply(name));

    final Function<String, By> classChainItemNameByName = name -> MobileBy.iOSClassChain(
            String.format("%s/XCUIElementTypeCell/**/XCUIElementTypeStaticText[`name == '%s' AND value == '%s'`]",
                    classChainStrViewRoot, nameStrItemName, name));

    public void selectItem(String name) {
        getElement(classChainItemNameByName.apply(name)).click();
    }

    public boolean isItemVisible(String name) {
        return isLocatorDisplayed(classChainItemCellByName.apply(name));
    }

    public boolean isItemInvisible(String name) {
        return isLocatorInvisible(classChainItemCellByName.apply(name));
    }

    private static By getLocatorByLabelName(String name) {
        switch (name.toLowerCase()) {
            case "no results":
                return nameNoResults;
            case "everyone is here":
                return predicateEveryoneIsHere;
            default:
                throw new IllegalArgumentException(String.format("Unknown message label: '%s'", name));
        }
    }

    public boolean waitUntilResultsLabelIsVisible(String label) {
        final By locator = getLocatorByLabelName(label);
        return isLocatorExist(locator);
    }

    public void typeSearchQuery(String text) {
        typeSearchQuery(text, false);
    }

    public void typeSearchQuery(String text, boolean shouldClearFieldBeforeInput) {
        final WebElement searchInput = getElement(predicateSearchInput);
        if (shouldClearFieldBeforeInput) {
            this.clearSearchQuery();
        }
        searchInput.sendKeys(text + " ");
    }

    public void clearSearchQuery() {
        final WebElement searchInput = getElement(predicateSearchInput);
        try {
            this.tapAtTheCenterOfElement(searchInput);
            searchInput.clear();
        } catch (WebDriverException e) {
            this.tapAtTheCenterOfElement(searchInput);
            searchInput.clear();
        }
    }
}
