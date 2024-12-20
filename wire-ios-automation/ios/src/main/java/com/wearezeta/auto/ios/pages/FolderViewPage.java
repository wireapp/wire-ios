package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.CommonUtils;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.MobileBy;

import java.util.*;
import java.util.logging.Logger;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;

public class FolderViewPage extends IOSPage {
    private static final Logger log = ZetaLogger.getLog(ConversationsListPage.class.getSimpleName());

    @iOSXCUITFindBy(xpath = "//XCUIElementTypeCollectionView[@name=\"conversation list\"]/*")
    List<WebElement> conversationListItems;

    @iOSXCUITFindBy(accessibility = "PEOPLE")
    WebElement peopleFolder;

    @iOSXCUITFindBy(xpath = "//XCUIElementTypeCell[@name=\"contacts - conversation_list_cell\"]/*")
    WebElement peopleFolderItems;

    public FolderViewPage(WebDriver driver) {
        super(driver);
    }

    private static final By nameFolderViewRoot =
            MobileBy.iOSNsPredicateString("name ENDSWITH 'bottomBarFolderListButton' AND label == 'List of conversations organized in folders'");

    private static final String classStrFolderViewRoot = "XCUIElementTypeCollectionView";
    private static final By classFolderViewRoot = By.className(classStrFolderViewRoot);

    private static final By nameGroupFolder = MobileBy.AccessibilityId("GROUPS");
    private static final String classChainStrGroupsFolderRoot =
            "**/XCUIElementTypeCell[`name == 'groups - conversation_list_cell'`]";
    private static final By nameFavoritesFolder = MobileBy.AccessibilityId("FAVORITES");
    private static final String classChainStrFavoritesFolderRoot =
            "**/XCUIElementTypeCell[`name == 'favorites - conversation_list_cell'`]";
    private static final String strNameConversation = "title";
    private static final String strFolderCollapsed = "collapsed";
    private static final String strFolderExpanded = "expanded";

    private static final By classChainConversationInList =
            MobileBy.iOSClassChain("**/XCUIElementTypeButton[`name == 'title'`]");

    private static final Function<String, By> predicateStrConversationByLabel = text ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND label == '%s'", strNameConversation, text));

    private static final Function<String, By> predicateStrIsFolderCollapsed = folderName ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND value BEGINSWITH '%s'", folderName, strFolderCollapsed));

    private static final Function<String, By> predicateStrIsFolderExpanded = folderName ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND value BEGINSWITH '%s'", folderName, strFolderExpanded));

    private static final Function<String, String> classChainStrConversationInGroupsFolderByName = (nameConversation) -> String.format(
            "%s/**/XCUIElementTypeButton[`name == 'title' && label == '%s'`]",
            classChainStrGroupsFolderRoot, nameConversation);

    private static final Function<String, String> classChainStrConversationInFavoritesFolderByName = (nameConversation) -> String.format(
            "%s/**/XCUIElementTypeButton[`name == 'title' && label == '%s'`]",
            classChainStrFavoritesFolderRoot, nameConversation);

    private static final BiFunction<String, String, By> predicatedStrRelativeConversationStatusByValue = (label, value) ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND label == '%s' AND value ENDSWITH '%s'", strNameConversation, label, value));

    private static final BiFunction<String, String, By> predicateStrSecondaryLine = (label, value) ->
            MobileBy.iOSNsPredicateString(String.format("name == '%s' AND  label == '%s' AND value BEGINSWITH '%s'", strNameConversation, label, value));

    private static final BiFunction<String, Integer, String> predicateStrFolderBadgeCount = (folderName, number) -> String.format(
            "name == '%s' AND value ENDSWITH ' %s'", folderName, number);

    private static final Function<String, String> predicateStrFolderBadge = (folderName) -> String.format(
            "name == '%s' AND value CONTAINS 'New messages:'", folderName);

    public boolean isVisible() {
        return isLocatorDisplayed(nameFolderViewRoot, Timedelta.ofSeconds(10));
    }

    public boolean isPeopleFolderVisible() {
        return waitUntilElementVisible(peopleFolder);
    }

    public boolean isPeopleFolderInvisible() {
        return waitUntilElementInvisible(peopleFolder);
    }

    public boolean isFavoritesFolderVisible() {
        return isLocatorDisplayed(nameFavoritesFolder);
    }

    public boolean isFavoritesFolderInvisible() {
        return isLocatorInvisible(nameFavoritesFolder);
    }

    public void tapPeopleFolder() {
        peopleFolder.click();
    }

    public void tapFavoritesFolder() {
        getElement(nameFavoritesFolder).click();
    }
    public void tapCustomFolder(String folderName) {
        getElement(MobileBy.AccessibilityId(folderName.toUpperCase())).click();
    }

    public boolean isGroupFolderVisible() {
        return isLocatorDisplayed(nameGroupFolder);
    }

    public boolean isGroupFolderInvisible() {
        return isLocatorInvisible(nameGroupFolder);
    }

    public boolean isCustomFolderVisible(String name) {
        return isLocatorDisplayed(MobileBy.AccessibilityId(name.toUpperCase()));
    }

    public boolean isCustomFolderInvisible(String name) {
        return isLocatorInvisible(MobileBy.AccessibilityId(name.toUpperCase()));
    }

    public boolean isFolderExpanded(String folderName) {
        return isLocatorDisplayed(predicateStrIsFolderExpanded.apply(folderName.toUpperCase()));
    }

    public boolean isFolderCollapsed(String folderName) {
      return isLocatorDisplayed(predicateStrIsFolderCollapsed.apply(folderName.toUpperCase()));
    }

    public boolean isConversationInGroupsFolder(String conversationName) {
        final By locator = MobileBy.iOSClassChain(classChainStrConversationInGroupsFolderByName.apply(conversationName));
        return isLocatorDisplayed(locator);
    }

    public boolean isConversationNotInGroupsFolder(String conversationName) {
        final By locator = MobileBy.iOSClassChain(classChainStrConversationInGroupsFolderByName.apply(conversationName));
        return isLocatorInvisible(locator);
    }

    public boolean isConversationInFavoritesFolder(String conversationName) {
        final By locator = MobileBy.iOSClassChain(classChainStrConversationInFavoritesFolderByName.apply(conversationName));
        return isLocatorDisplayed(locator);
    }

    public boolean isConversationNotInFavoritesFolder(String conversationName) {
        final By locator = MobileBy.iOSClassChain(classChainStrConversationInFavoritesFolderByName.apply(conversationName));
        return isLocatorInvisible(locator);
    }

    public List<String> getConversationOfPeopleFolder() {
        List<WebElement> buttons = peopleFolderItems.findElements(classChainConversationInList);
        return buttons.stream().map(button -> button.getAttribute("label")).collect(Collectors.toList());
    }

    public List<String> getConversationsInCustomFolder(String folderName) {
        List<Folder> folders = getConversationsWithFolderInformation();
        for (Folder folder : folders) {
            log.info("Folder " + folder.name + " contains: " + String.join(",", folder.conversations));
            if (folder.name.equalsIgnoreCase(folderName)) {
                return folder.conversations;
            }
        }
        return Collections.emptyList();
    }

    // data structure to hold folder names and conversations in folder
    private class Folder {
        public String name;
        public List<String> conversations = new ArrayList<>();

        public Folder(String name) {
            this.name = name;
        }

        public void addConversation(String name) {
            conversations.add(name);
        }
    }

    // This method creates a map containing the conversation name and the custom folder in which it is
    public List<Folder> getConversationsWithFolderInformation() {
        List<Folder> folders = new ArrayList<>();
        Folder currentFolder = null;
        // Create
        for (WebElement element : conversationListItems) {
            if (element.getAttribute("type").equals("XCUIElementTypeOther")) {
                // If folder element: remember which is the current custom folder
                currentFolder = new Folder(element.getAttribute("label"));
                folders.add(currentFolder);
            } else if (element.getAttribute("type").equals("XCUIElementTypeCell")) {
                // If conversation element: get individual conversation element
                WebElement button = element.findElement(classChainConversationInList);
                currentFolder.addConversation(button.getAttribute("label"));
            }
        }
        return folders;
    }

    public boolean isConversationItemWithStatusVisible(String status, String conversation) {
        final WebElement root = getElement(classFolderViewRoot);
        return isLocatorDisplayed(root, predicatedStrRelativeConversationStatusByValue.apply(conversation, status));
    }

    public boolean isConversationItemWithStatusInvisible(String status, String conversation) {
        final WebElement root = getElement(classFolderViewRoot);
        return isLocatorInvisible(root, predicatedStrRelativeConversationStatusByValue.apply(conversation, status));
    }

    public boolean isSecondaryLineVisible(String conversation, String secondaryLine) {
        final By locator = predicateStrSecondaryLine.apply(conversation, secondaryLine);
        return isLocatorDisplayed(locator, Timedelta.ofSeconds(3));
    }

    public boolean isSecondaryLineInvisible(String conversation, String secondaryLine) {
        final By locator = predicateStrSecondaryLine.apply(conversation, secondaryLine);
        return isLocatorInvisible(locator, Timedelta.ofSeconds(3));
    }

    public void tapConversationItemGroupedList(String conversationName) {
            getConversationsListItem(conversationName, Timedelta.ofSeconds(10)).click();
    }

    public void swipeRightOnGroupedConversation(String name) {
        final WebElement convoListItem = getConversationsListItem(name, Timedelta.ofSeconds(5));
        if (!CommonUtils.waitUntilTrue(Timedelta.ofSeconds(5), Timedelta.ofMillis(1), () -> {
            swipe(convoListItem, SwipeDirection.RIGHT);
            return isElementInvisible(convoListItem, Timedelta.ofSeconds(1));
        })) {
            log.warning(String.format("The conversation item '%s' is still visible after being swiped to the right", name));
        }
    }

    private WebElement getConversationsListItem(String name, Timedelta timeout) {
        final By locator = predicateStrConversationByLabel.apply(name);
        return getElement(locator,
                String.format("The conversation '%s' is not visible in the list after %s", name, timeout), timeout);
    }

    public boolean isBadgeCountForFolder(String folderName, int number) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrFolderBadgeCount.apply(folderName.toUpperCase(), number));
        return isLocatorDisplayed(locator);
    }

    public boolean isBadgeCountInvisibleForFolder(String folderName) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrFolderBadge.apply(folderName.toUpperCase()));
        return isLocatorInvisible(locator);
    }
}