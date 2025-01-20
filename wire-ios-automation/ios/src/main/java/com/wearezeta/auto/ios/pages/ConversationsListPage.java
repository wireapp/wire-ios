package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.Config;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.MobileBy;
import java.util.logging.Logger;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.BiFunction;
import java.util.function.Function;

public class ConversationsListPage extends IOSPage {
    private static final Logger log = ZetaLogger.getLog(ConversationsListPage.class.getSimpleName());

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'conversation list'")
    private WebElement conversationsListRoot;

    @iOSXCUITFindBy(className = "XCUIElementTypeCollectionView")
    private WebElement classConversationsListRoot;

    @iOSXCUITFindBy(iOSNsPredicate = "name BEGINSWITH 'Start a conversation'")
    private WebElement inviteHelpText;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'action_button' AND type == 'XCUIElementTypeButton'")
    private WebElement joinButton;

    @iOSXCUITFindBy(accessibility = "EVERYTHING ARCHIVED")
    private WebElement conversationListPlaceholder;

    @iOSXCUITFindBy(accessibility = "ClassificationBannerClassified")
    private WebElement classifiedDomainLabel;

    @iOSXCUITFindBy(accessibility = "ClassificationBannerUnclassified")
    private WebElement unClassifiedDomainLabel;

    @iOSXCUITFindBy(accessibility = "contactRequests - conversation_list_cell")
    private WebElement conversationPendingRequest;

    @iOSXCUITFindBy(accessibility = "Mark as Read")
    private WebElement markAsRead;

    @iOSXCUITFindBy(accessibility = "Mute")
    private WebElement mute;

    @iOSXCUITFindBy(accessibility = "Nothing")
    private WebElement nothing;

    @iOSXCUITFindBy(accessibility = "Notifications…")
    private WebElement notificationsMenu;

    @iOSXCUITFindBy(accessibility = "Archive")
    private WebElement archive;

    @iOSXCUITFindBy(accessibility = "Add to Favorites")
    private WebElement addToFavorites;

    @iOSXCUITFindBy(accessibility = "Remove from Favorites")
    private WebElement removeFromFavorites;

    @iOSXCUITFindBy(accessibility = "Move to…")
    private WebElement moveTo;

    @iOSXCUITFindBy(accessibility = "Clear Content…")
    private WebElement clearContent;

    @iOSXCUITFindBy(accessibility = "Clear")
    private WebElement clearInClearContent;

    @iOSXCUITFindBy(accessibility = "Block…")
    private WebElement block;

    @iOSXCUITFindBy(accessibility = "Block")
    private WebElement blockConfirm;

    @iOSXCUITFindBy(accessibility = "Leave Group…")
    private WebElement leaveGroup;

    @iOSXCUITFindBy(accessibility = "Leave and clear content")
    private WebElement leaveAndClearConfirm;

    @iOSXCUITFindBy(accessibility = "Name")
    private WebElement name;

    private static final Function<String, By> predicateStrConversationByLabel = text ->
            MobileBy.iOSNsPredicateString(String.format("name == 'title' AND label == '%s'", text));

    private static final Function<String, By> xpathStrFirstConversationRelativeEntryByName = name ->
            MobileBy.xpath(String.format("//XCUIElementTypeOther[1]/XCUIElementTypeButton[@label='%s']", name));

    private static final BiFunction<String, String, By> predicateStrSecondaryLine = (label, value) ->
            MobileBy.iOSNsPredicateString(String.format("name == 'title' AND  label == '%s' AND value BEGINSWITH '%s'", label, value));

    private static final Function<String, By> classChainStrRelativeConversationStatus = name -> MobileBy.iOSClassChain(String.format(
            "XCUIElementTypeCell[$type == 'XCUIElementTypeButton' AND label == '%s' AND `name == 'title' $]",
            name));

    private static final BiFunction<String, String, By> predicatedStrRelativeConversationStatusByValue = (label, value) ->
            MobileBy.iOSNsPredicateString(String.format("name == 'title' AND label == '%s' AND value ENDSWITH '%s'", label, value));

    public ConversationsListPage(WebDriver driver) {
        super(driver);
    }

    public void tapConversationItemRecentList(String name) {
        final By locator = predicateStrConversationByLabel.apply(name);
        getDriver().findElement(locator).click();
    }

    // TODO: Not sure if I like how handling the context menu at the moment
    public void tapMarkAsRead() {
        markAsRead.click();
    }

    public void tapNotificationsMenu() {
        notificationsMenu.click();
    }

    public void tapNothing() {
        nothing.click();
    }

    public void tapArchive() {
        archive.click();
    }

    public void tapFavorite() {
        addToFavorites.click();
    }

    public void tapRemoveFromFavorite() {
        removeFromFavorites.click();
    }

    public void tapMoveTo() {
        moveTo.click();
    }

    public void tapClearContent() {
        clearContent.click();
    }

    public void tapBlock() {
        block.click();
    }

    public void tapLeaveGroup() {
        leaveGroup.click();
    }

    public void longTapConversationItemRecentList(String name) {
        final By locator = predicateStrConversationByLabel.apply(name);
        try {
            longTapWithActionsAPI(getDriver().findElement(locator));
        } catch (InterruptedException e) {
            throw new RuntimeException("The long tap action was interrupted", e);
        }
    }

    public boolean isConversationInList(String name) {
        return this.isConversationInList(name,
                Timedelta.ofSeconds(Integer.parseInt(Config.current().getDriverTimeout(getClass()))));
    }

    public boolean isConversationInList(String name, Timedelta timeout) {
        final By locator = predicateStrConversationByLabel.apply(name);
        return isLocatorDisplayed(locator, timeout);
    }

    public void swipeRightOnConversation(String name) {
        final By locator = predicateStrConversationByLabel.apply(name);
        final WebElement convoListItem = getDriver().findElement(locator);
        if (!CommonUtils.waitUntilTrue(Timedelta.ofSeconds(5), Timedelta.ofMillis(1), () -> {
            swipe(convoListItem, SwipeDirection.RIGHT);
            return isElementInvisible(convoListItem, Timedelta.ofSeconds(1));
        })) {
            log.warning(String.format("The conversation item '%s' is still visible after being swiped to the right", name));
        }
    }

    public boolean isPendingRequestInContactList() {
        return conversationPendingRequest.isDisplayed();
    }

    public boolean pendingRequestInContactListIsNotShown() {
        return isElementInvisible(conversationPendingRequest);
    }

    public void tapPendingRequest() {
        conversationPendingRequest.click();
    }

    public boolean isConversationNotInList(String name, Timedelta timeout) {
        final By locator = predicateStrConversationByLabel.apply(name);
        return isLocatorInvisible(locator, timeout);
    }

    public boolean isConversationNotInList(String name) {
        return isConversationNotInList(name, getDefaultLookupTimeout());
    }

    public boolean isFirstConversationName(String convoName) {
        return isLocatorDisplayed(classConversationsListRoot, xpathStrFirstConversationRelativeEntryByName.apply(convoName));
    }

    public boolean isConversationsListPlaceholderVisible() {
        return conversationListPlaceholder.isDisplayed();
    }

    public boolean isConversationItemWithStatusVisible(String status, String conversation) {
        return isLocatorDisplayed(classConversationsListRoot, predicatedStrRelativeConversationStatusByValue.apply(conversation, status));
    }

    public boolean isConversationItemWithStatusInvisible(String status, String conversation) {
        return isLocatorInvisible(classConversationsListRoot, predicatedStrRelativeConversationStatusByValue.apply(conversation, status));
    }

    public boolean isConversationItemStatusInvisible(String conversation) {
        return isLocatorInvisible(classConversationsListRoot, classChainStrRelativeConversationStatus.apply(conversation));
    }

    public boolean isConversationItemStatusVisible(String conversation) {
        return isLocatorDisplayed(classConversationsListRoot, classChainStrRelativeConversationStatus.apply(conversation));
    }

    public boolean isSecondaryLineVisible(String conversation, String secondaryLine) {
        final By locator = predicateStrSecondaryLine.apply(conversation, secondaryLine);
        return isLocatorDisplayed(locator, Timedelta.ofSeconds(3));
    }

    public boolean isVisible() {
        return isElementVisible(conversationsListRoot, Timedelta.ofSeconds(10));
    }

    public boolean isInvisible() {
        return isElementInvisible(conversationsListRoot);
    }

    public void tapJoinButtonNextTo(String name) {
        isLocatorDisplayed(classConversationsListRoot, predicatedStrRelativeConversationStatusByValue.apply(name, "JOIN"));
        joinButton.click();
    }

    public boolean isClassifiedLabelVisible() {
        return classifiedDomainLabel.isDisplayed();
    }

    public boolean isClassifiedLabelInvisible() {
        return isElementInvisible(classifiedDomainLabel);
    }

    public boolean isNotClassifiedLabelVisible() {
        return unClassifiedDomainLabel.isDisplayed();
    }

    public boolean isNotClassifiedLabelInvisible() {
        return isElementInvisible(classifiedDomainLabel);
    }

    public boolean isClassifiedLabelVisibleConvo() {
        return classifiedDomainLabel.isDisplayed();
    }

    public boolean isClassifiedLabelInvisibleConvo() {
        return isElementInvisible(classifiedDomainLabel);
    }

    public boolean isNotClassifiedLabelVisibleConvo() {
        return unClassifiedDomainLabel.isDisplayed();
    }

    public boolean isNotClassifiedLabelInvisibleConvo() {
        return isElementInvisible(unClassifiedDomainLabel);
    }

    public boolean isClassifiedLabelVisibleUserProfile() {
        return classifiedDomainLabel.isDisplayed();
    }

    public boolean isClassifiedLabelInvisibleUserProfile() {
        return isElementInvisible(classifiedDomainLabel);
    }

    public boolean isNotClassifiedLabelVisibleUserProfile() {
        return unClassifiedDomainLabel.isDisplayed();
    }

    public boolean isNotClassifiedLabelInvisibleUserProfile() {
        return isElementInvisible(unClassifiedDomainLabel);
    }

    public void tapClearInClearContent() {
        clearInClearContent.click();
    }

    public void tapBlockConfirm() {
        blockConfirm.click();
    }

    public void tapLeaveAndClearConfirm() {
        leaveAndClearConfirm.click();
    }

    public boolean isCertified() {
        return name.getAttribute("label").contains("all your devices have a valid end-to-end identity certificate");
    }
}
