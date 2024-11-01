package com.wearezeta.auto.ios.pages;

import java.util.function.Function;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.search.SearchList;
import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.*;

import org.openqa.selenium.WebDriver;

public class SearchUIPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    @iOSXCUITFindBy(accessibility = "Search by name or username")
    private WebElement searchBar;

    @iOSXCUITFindBy(accessibility = "Copy")
    private WebElement copyInviteButton;

    @iOSXCUITFindBy(accessibility = "Invite More People")
    private WebElement inviteMorePeopleButton;

    /**
    @iOSXCUITFindBy(accessibility = "button.searchui.creategroup")
    private WebElement createGroupButton;
*/
    @iOSXCUITFindBy(accessibility = "button.searchui.createguestroom")
    private WebElement createGuestRoomButton;

    @iOSXCUITFindBy(accessibility= "create_group")
    private WebElement createGroupButton;

    private static final Function<Integer, By> classChainTopPeopleAvatarByIdx = idx -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCell[`name == 'TopPeopleCell'`][%s]", idx));

    private static final Function<String, By> predicateStringServiceSearchResult = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND value == '%s'", name));

    private static final Function<String, By> serviceNameByText = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND value == '%s'", name));

    private static final Function<String, By> predicateContact = name -> MobileBy.iOSNsPredicateString(
            String.format("name == 'user_cell.name' AND value == '%s'", name));

    private final SearchList searchList;

    public SearchUIPage(WebDriver driver) {
        super(driver);
        this.searchList = new SearchList(driver);
    }

    public boolean isVisible() {
        return searchList.isVisible();
    }

    public void typeSearchQuery(String text, boolean shouldClearFieldBeforeInput) {
//        searchList.typeSearchQuery(text, shouldClearFieldBeforeInput);
        searchBar.sendKeys(text);
        // Wait for a user to be found
        Timedelta.ofSeconds(2).sleep();
    }

    public void clearSearchInput() {
        searchList.clearSearchQuery();
    }

    public void tapCreateGroupButton() {
        createGroupButton.click();
    }

    public void tapCloseButton() {
        closeButton.click();
    }

    public void tapSendInviteButton() {
        inviteMorePeopleButton.click();
    }

    public void tapCopyInviteButton() {
      copyInviteButton.click();
    }

    public boolean isElementFoundInSearch(String name) {
        return searchList.isItemVisible(name);
    }

    public boolean isElementNotFoundInSearch(String name) {
        return searchList.isItemInvisible(name);
    }

    public void selectElementInSearchResults(String name) {
        searchList.selectItem(name);
    }

    public void tapTopConnectionsAvatars(int numberToTap) {
        for (int i = 1; i <= numberToTap; i++) {
            final By locator = classChainTopPeopleAvatarByIdx.apply(i);
            getElement(locator).click();
        }
    }

    public void tapInstantConnectButton(String name) {
        searchList.tapInstantConnectButton(name);
    }

    public void tapOnTopConnectionAvatarByOrder(int i) {
        final By locator = classChainTopPeopleAvatarByIdx.apply(i);
        getDriver().findElement(locator).click();
    }

    public int getOccurrencesCount(String name) {
        return searchList.getOccurrencesCount(name);
    }

    public boolean isContactVisible(String text) {
        final By locator = predicateContact.apply(text);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isContactInvisible(String text) {
        final By locator = predicateContact.apply(text);
        return isLocatorInvisible(locator);
    }

    public boolean isServiceVisibleInSearchResult(String serviceName) {
        final By locator = predicateStringServiceSearchResult.apply(serviceName);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isServiceInVisibleInSearchResult(String serviceName) {
        final By locator = predicateStringServiceSearchResult.apply(serviceName);
        return isLocatorInvisible(locator);
    }

    public void tapOnService(String serviceName) {
        getDriver().findElement(serviceNameByText.apply(serviceName)).click();
    }

    public boolean isCreateGroupButtonVisible() {
        return isElementVisible(createGroupButton);
    }

    public boolean isCreateGroupButtonInvisible() {
        return waitUntilElementInvisible(createGroupButton);
    }

    public boolean isCreateGuestRoomButtonVisible() {
        return isElementVisible(createGuestRoomButton);
    }

    public boolean isCreateGuestRoomButtonInvisible() {
        return waitUntilElementInvisible(createGuestRoomButton);
    }

    public void iOpenCreateGroupScreen() {
        createGroupButton.click();
    }
}
