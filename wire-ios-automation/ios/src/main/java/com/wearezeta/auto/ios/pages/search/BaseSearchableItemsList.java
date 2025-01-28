package com.wearezeta.auto.ios.pages.search;

import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.Keys;
import org.openqa.selenium.WebDriverException;
import org.openqa.selenium.WebElement;

import java.util.function.BiFunction;
import java.util.function.Function;

public abstract class BaseSearchableItemsList extends IOSPage {
    private String classChainStrViewRoot;

    private static final String nameStrSearchInput = "textViewSearch";

    private static final By predicateSearchInput = MobileBy.iOSNsPredicateString(isTablet() ?
            String.format("type == 'XCUIElementTypeTextView' AND name == '%s' AND visible == 1", nameStrSearchInput) :
            String.format("type == 'XCUIElementTypeTextView' AND name == '%s'", nameStrSearchInput));

    private static final By nameNoResults = MobileBy.AccessibilityId("No results.");

    private static final By predicateEveryoneIsHere =
            MobileBy.iOSNsPredicateString("value BEGINSWITH 'Everyone' AND value ENDSWITH 'here.'");

    private static final String nameStrItemName = "user_cell.name";
    private static final String nameStrItemUsername = "user_cell.username";
    static final String nameStrParticipantCell = "participants.section.participants.cell";
    static final By nameParticipantCell = MobileBy.iOSNsPredicateString("name ENDSWITH 'participants.section.participants.cell'");
    static final String nameStrServiceCellName = "participants.section.services.cell";
    static final By nameServiceCellName = MobileBy.AccessibilityId("participants.section.services.cell");

    private final BiFunction<String, String, String> classChainStrItemCellByCellAndName = (name, cellName) ->
            String.format("%s/XCUIElementTypeCell[`name ENDSWITH '%s'`][$name == '%s' AND value == '%s' OR name == '%s' AND value == '%s (You)'$]",
                    classChainStrViewRoot, cellName, nameStrItemName, name, nameStrItemName, name);

    private final BiFunction<String, String, String> classChainStrFederatedGroupDetailsItemCellByCellAndName = (name, cellName) ->
            String.format("%s/XCUIElementTypeCell[`name ENDSWITH '%s'`][$name == '%s' AND value == '%s' OR name == '%s' AND value == '%s (You)'$]",
                    classChainStrViewRoot, cellName, nameStrItemUsername, name, nameStrItemUsername, name);

    final BiFunction<String, String, By> classChainItemCellByCellAndName = (name, cellName) ->
            MobileBy.iOSClassChain(classChainStrItemCellByCellAndName.apply(name, cellName));

    final BiFunction<String, String, By> classChainFederatedGroupDetailsItemCellByCellAndName = (name, cellName) ->
            MobileBy.iOSClassChain(classChainStrFederatedGroupDetailsItemCellByCellAndName.apply(name, cellName));

    private final BiFunction<String, String, By> classChainItemNameByCellAndName = (name, cellName) ->
            MobileBy.iOSClassChain(String.format("%s/XCUIElementTypeCell[`name ENDSWITH '%s'`]/" +
                            "**/XCUIElementTypeStaticText[`name == '%s' AND value == '%s' OR name == '%s' AND value == '%s (You)'`]",
                    classChainStrViewRoot, cellName, nameStrItemName, name, nameStrItemName, name));

    private final BiFunction<String, String, By> classChainItemCellByCellWithUniqueUsername = (name, cellName) ->
            MobileBy.iOSClassChain(String.format("%s[$name == '%s'$]",
                    classChainStrItemCellByCellAndName.apply(name, cellName), nameStrItemUsername));

    private final BiFunction<String, String, By> classChainGuestIconForParticipantByCellAndName = (name, cellName) ->
            MobileBy.iOSClassChain(String.format("%s/**/XCUIElementTypeImage[`name == 'img.guest'`]",
                    classChainStrItemCellByCellAndName.apply(name, cellName)));

    private final BiFunction<String, String, By> classChainFederatedIconForParticipantByCellAndName = (name, cellName) ->
            MobileBy.iOSClassChain(String.format("%s/**/XCUIElementTypeImage[`name == 'img.federated'`]",
                    classChainStrItemCellByCellAndName.apply(name, cellName)));

    private final BiFunction<String, String, By> classChainExternalIconForParticipantByCellAndName = (name, cellName) ->
            MobileBy.iOSClassChain(String.format("%s/**/XCUIElementTypeImage[`name == 'img.external'`]",
                    classChainStrItemCellByCellAndName.apply(name, cellName)));

    private final Function<String, String> classChainStrItemCellByName = name ->
            String.format("%s/XCUIElementTypeCell[$name == '%s' AND value == '%s'$]",
                    classChainStrViewRoot, nameStrItemName, name);

    private final Function<String, String> classChainStrFederatedItemCellByName = name ->
            String.format("%s/XCUIElementTypeCell[$name == '%s' AND value == '%s'$]",
                    classChainStrViewRoot, nameStrItemUsername, name);

    final Function<String, By> classChainItemCellByName = name -> MobileBy.iOSClassChain(
            classChainStrItemCellByName.apply(name));

    final Function<String, By> classChainFederatedItemCellByName = name -> MobileBy.iOSClassChain(
            classChainStrFederatedItemCellByName.apply(name));

    final Function<String, By> classChainItemNameByName = name -> MobileBy.iOSClassChain(
            String.format("%s/XCUIElementTypeCell/**/XCUIElementTypeStaticText[`name == '%s' AND value == '%s'`]",
                    classChainStrViewRoot, nameStrItemName, name));

    private final Function<String, By> classChainItemCellByNameWithUniqueUsername = name ->
            MobileBy.iOSClassChain(String.format("%s[$name == '%s'$]", classChainStrItemCellByName.apply(name),
                    nameStrItemUsername));

    private final Function<String, By> classChainGuestIconForParticipantByName = name -> MobileBy.iOSClassChain(
            String.format("%s/**/XCUIElementTypeImage[`name == 'img.guest'`]", classChainStrItemCellByName.apply(name)));

    private final Function<String, By> classChainExternalIconForParticipantByName = name -> MobileBy.iOSClassChain(
            String.format("%s/**/XCUIElementTypeImage[`name == 'img.external'`]", classChainStrItemCellByName.apply(name)));

    private final Function<String, By> classChainVerifiedIconForParticipantByName = name -> MobileBy.iOSClassChain(
            String.format("%s/**/XCUIElementTypeImage[`name == 'img.shield'`]", classChainStrItemCellByName.apply(name)));

    public BaseSearchableItemsList(WebDriver driver, String classChainStrViewRoot) {
        super(driver);
        this.classChainStrViewRoot = classChainStrViewRoot;
    }

    public boolean isVisible() {
        return isLocatorDisplayed(MobileBy.iOSClassChain(classChainStrViewRoot), Timedelta.ofSeconds(2));
    }

    public boolean isParticipantCellVisible() {
        return isLocatorDisplayed(nameParticipantCell, Timedelta.ofSeconds(2));
    }

    boolean isUniqueUserNameLabelVisibleFor(String cellName, String name) {
        return isLocatorDisplayed(classChainItemCellByCellWithUniqueUsername.apply(name, cellName));
    }

    boolean isUniqueUserNameLabelInvisibleFor(String cellName, String name) {
        return isLocatorInvisible(classChainItemCellByCellWithUniqueUsername.apply(name, cellName));
    }

    void selectItem(String cellName, String name) {
        getElement(classChainItemNameByCellAndName.apply(name, cellName)).click();
    }

    boolean isItemVisible(String cellName, String name) {
        return isLocatorDisplayed(classChainItemCellByCellAndName.apply(name, cellName), Timedelta.ofSeconds(2));
    }

    boolean isItemInvisible(String cellName, String name) {
        return isLocatorInvisible(classChainItemCellByCellAndName.apply(name, cellName), Timedelta.ofSeconds(1));
    }

    boolean isFederatedItemVisibleOnGroupDetails(String cellName, String name) {
        return isLocatorDisplayed(classChainFederatedGroupDetailsItemCellByCellAndName.apply(name, cellName));
    }

    boolean isFederatedItemInvisibleOnGroupDetails(String cellName, String name) {
        return isLocatorInvisible(classChainFederatedGroupDetailsItemCellByCellAndName.apply(name, cellName));
    }

    boolean isGuestLabelVisibleFor(String cellName, String name) {
        return isLocatorExist(classChainGuestIconForParticipantByCellAndName.apply(name, cellName));
    }

    boolean isGuestLabelInvisibleFor(String cellName, String name) {
        return isLocatorInvisible(classChainGuestIconForParticipantByCellAndName.apply(name, cellName));
    }

    boolean isExternalIconVisibleFor(String cellName, String name) {
        return isLocatorExist(classChainExternalIconForParticipantByCellAndName.apply(name, cellName));
    }

    protected boolean isUniqueUserNameLabelVisibleFor(String name) {
        return isLocatorDisplayed(classChainItemCellByNameWithUniqueUsername.apply(name));
    }

    protected boolean isUniqueUserNameLabelInvisibleFor(String name) {
        return isLocatorInvisible(classChainItemCellByNameWithUniqueUsername.apply(name));
    }

    protected void selectItem(String name) {
        getElement(classChainItemNameByName.apply(name)).click();
    }

    protected boolean isItemVisible(String name) {
        return isLocatorDisplayed(classChainItemCellByName.apply(name));
    }

    protected boolean isItemInvisible(String name) {
        return isLocatorInvisible(classChainItemCellByName.apply(name));
    }

    protected boolean isFederatedItemVisible(String name) {
        return isLocatorDisplayed(classChainFederatedItemCellByName.apply(name));
    }

    protected boolean isFederatedItemInvisible(String name) {
        return isLocatorInvisible(classChainFederatedItemCellByName.apply(name));
    }

    boolean isVerifiedLabelVisibleFor(String name) {
        return isLocatorExist(classChainVerifiedIconForParticipantByName.apply(name));
    }

    protected boolean isGuestLabelVisibleFor(String name) {
        return isLocatorExist(classChainGuestIconForParticipantByName.apply(name));
    }

    protected boolean isExternalLabelVisibleFor(String name) {
        return isLocatorExist(classChainExternalIconForParticipantByName.apply(name));
    }

    protected boolean isExternalLabelInvisibleFor(String name) {
        return isLocatorInvisible(classChainExternalIconForParticipantByName.apply(name));
    }

    protected boolean isGuestLabelInvisibleFor(String name) {
        return isLocatorInvisible(classChainGuestIconForParticipantByName.apply(name));
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

    protected void typeSearchQuery(String text) {
        typeSearchQuery(text, false);
    }

    protected void typeSearchQuery(String text, boolean shouldClearFieldBeforeInput) {
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
    protected void sendKeysToSearchInput(Keys... keys) {
        for (Keys key : keys) {
            getElement(predicateSearchInput).sendKeys(key);
        }
    }

    protected String getCurrentSearchQuery() {
        return getElement(predicateSearchInput).getText();
    }

    boolean isFederatedLabelVisibleFor(String cellName, String name) {
        return isLocatorExist(classChainFederatedIconForParticipantByCellAndName.apply(name, cellName));
    }
}

