package com.wearezeta.auto.ios.pages.search;

import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import java.util.function.Function;

public class MentionSuggestionsList extends BaseSearchableItemsList {

    private static final String classChainStrViewRoot = "**/XCUIElementTypeCollectionView[`name == 'mentions.list.collection'`]";

    private static final Function<String, By> classChainRecentMention = username -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeTable/XCUIElementTypeCell[2]/**/XCUIElementTypeLink[`name == '@%s'`]", username));

    private static final Function<String, By> predicateSuggestionByName = name -> MobileBy.iOSNsPredicateString(
            String.format("name == 'user_cell.name' AND  value == '%s'", name));

    public MentionSuggestionsList(WebDriver driver) {
        super(driver, classChainStrViewRoot);
    }

    public void tapSuggestedMention(String username) {
        final By locator = predicateSuggestionByName.apply(username);
        getElement(locator).click();
    }

    public boolean isRecentMention(String username) {
        final By locator = classChainRecentMention.apply(username);
        return isLocatorDisplayed(locator);
    }

    public boolean isNotRecentMention(String username) {
        final By locator = classChainRecentMention.apply(username);
        return isLocatorInvisible(locator);
    }

    public boolean isGuestLabelVisibleFor(String name) {
        return super.isGuestLabelVisibleFor(name);
    }

    public boolean isExternalLabelVisibleFor(String name) {
        return super.isExternalLabelVisibleFor(name);
    }

    public boolean isVerifiedLabelVisibleFor(String name) {
        return super.isVerifiedLabelVisibleFor(name);
    }

    public boolean isSuggestionsVisible() {
        return isVisible();
    }
}