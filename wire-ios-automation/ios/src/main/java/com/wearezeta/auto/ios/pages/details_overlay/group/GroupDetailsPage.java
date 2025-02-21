package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.search.GroupParticipantsList;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriverException;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class GroupDetailsPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement exitGroupInfoPageButton;

    @iOSXCUITFindBy(accessibility = "OtherUserMetaControllerLeftButton")
    private WebElement addPeopleButton;

    @iOSXCUITFindBy(accessibility = "OtherUserMetaControllerRightButton")
    private WebElement openMenuButton;

    @iOSXCUITFindBy(accessibility = "group_details.list")
    private WebElement listRoot;

    @iOSXCUITFindBy(accessibility = "NameField")
    private WebElement conversationNameTextField;

    @iOSXCUITFindBy(accessibility = "ReadReceiptsSwitch")
    private WebElement toggleReadReceipts;

    @iOSXCUITFindBy(accessibility = "cell.groupdetails.guestoptions")
    private WebElement guestOptionsCell;

    @iOSXCUITFindBy(accessibility = "cell.groupdetails.servicesoptions")
    private WebElement servicesOptionsCell;

    @iOSXCUITFindBy(accessibility = "cell.groupdetails.timeoutoptions")
    private WebElement timedMessageOptionCell;

    @iOSXCUITFindBy(accessibility = "legalhold")
    private WebElement legalHoldIndicator;

    @iOSXCUITFindBy(iOSNsPredicate = "name BEGINSWITH 'GROUP MEMBERS'")
    private WebElement membersSection;

    @iOSXCUITFindBy(iOSNsPredicate = "name BEGINSWITH 'Participants'")
    private WebElement seeAllButton;

    private static final Function<String, By> predicateConversationNameByText = text -> MobileBy.iOSNsPredicateString(
            String.format("name == 'NameField' AND value == '%s'", text));

    private static final Function<String, By> classChainUserInAdminSection = userName ->
            MobileBy.iOSClassChain(String.format("**/XCUIElementTypeCollectionView[`name == " +
                    "'group_details.list'`]/*[`name == 'Admins - participants.section.participants.cell'`]/**/XCUIElementTypeStaticText[`value == '%s' OR value == '%s (You)'`]", userName, userName));

    private static final By classChainShowAllInAdminSection =
            MobileBy.iOSClassChain("**/XCUIElementTypeCollectionView[`name == " +
                    "'group_details.list'`]/*[`name == 'Admins - cell.call.show_all_participants'`]/**/XCUIElementTypeStaticText[`value BEGINSWITH 'Show All'`]");

    private static final Function<Integer, String> predicateStrMembersCount = count ->
            String.format("value == 'GROUP MEMBERS (%s)'", count);

    private static final Function<Integer, String> predicateStrAdminsCount = count ->
            String.format("value == 'GROUP ADMINS (%s)'", count);

    private final GroupParticipantsList participantsList;

    public GroupDetailsPage(WebDriver driver) {
        super(driver);
        this.participantsList = new GroupParticipantsList(driver);
    }


    public boolean isGroupNameEqualTo(String expectedName) {
        final By locator = predicateConversationNameByText.apply(expectedName);
        return isLocatorDisplayed(locator);
    }

    public void setGroupChatName(String name) {
        this.isKeyboardVisible();
        try {
            this.tapAtTheCenterOfElement(conversationNameTextField);
            this.tapAtTheCenterOfElement(conversationNameTextField);
            conversationNameTextField.clear();
        } catch (WebDriverException e) {
            this.tapAtTheCenterOfElement(conversationNameTextField);
            conversationNameTextField.clear();
        }
        conversationNameTextField.sendKeys(name);
        tapKeyboardCommitButton();
    }

    public boolean isGroupChatNameEnabled(){
        this.tapAtTheCenterOfElement(conversationNameTextField);
        return this.isKeyboardVisible();
    }

    public boolean isNumberOfMembersParticipantsEquals(int expectedNumber) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrMembersCount.apply(expectedNumber));
        if (!isLocatorDisplayed(locator, Timedelta.ofSeconds(3))) {
            // Sometimes the list is too long, so we need to scroll it a bit
            this.swipe(listRoot, SwipeDirection.UP);
            return isLocatorDisplayed(locator, Timedelta.ofSeconds(5));
        }
        return true;
    }

    public boolean isNumberOfAdminsParticipantsEquals(int expectedNumber) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrAdminsCount.apply(expectedNumber));
        if (!isLocatorDisplayed(locator, Timedelta.ofSeconds(3))) {
            // Sometimes the list is too long, so we need to scroll it a bit
            this.swipe(listRoot, SwipeDirection.UP);
            return isLocatorDisplayed(locator, Timedelta.ofSeconds(5));
        }
        return true;
    }

    public int getGroupNameLength() {
        return conversationNameTextField.getText().length();
    }

    public void tapAddPeopleButton() {
        addPeopleButton.click();
    }

    public void tapOpenMenuButton() {
        openMenuButton.click();
    }

    public void tapXButton() {
        waitUntilElementClickable(exitGroupInfoPageButton);
        exitGroupInfoPageButton.click();
    }

    public boolean isAddPeopleButtonVisible() {
        return addPeopleButton.isDisplayed();
    }

    public boolean isAddPeopleButtonInvisible() {
        return isElementInvisible(addPeopleButton);
    }

    public boolean isExternalIndicatorVisibleFor(String name) {
        return participantsList.isExternalIconVisibleFor(name);
    }

    public void openGuestOptions() {
        guestOptionsCell.click();
    }

    public boolean isGuestOptionsVisible() {
        return guestOptionsCell.isDisplayed();
    }

    public boolean isGuestOptionsInvisible() {
        return isElementInvisible(guestOptionsCell);
    }

    public boolean isServicesOptionsVisible() {
        return servicesOptionsCell.isDisplayed();
    }

    public void selectParticipant(String name) {
        if (participantsList.isParticipantVisible(name)) {
            participantsList.selectParticipant(name);
        } else {
            int nScroll = 0;
            int maxScroll = 2;
            while (participantsList.isParticipantInvisible(name) && nScroll <= maxScroll) {
                //scroll down
                this.swipe(listRoot, SwipeDirection.UP);
                nScroll++;
            }
            if (participantsList.isParticipantInvisible(name)) {
                nScroll = 0;
                while(participantsList.isParticipantInvisible(name) && nScroll <= maxScroll){
                    //scroll up
                    this.swipe(listRoot, SwipeDirection.DOWN);
                    nScroll++;
                }
            }
            participantsList.selectParticipant(name);
        }
    }

    public int getServicesCount() {
        return participantsList.getServicesCount();
    }

    public int getParticipantsCount() {
        if (!participantsList.isParticipantCellVisible()) {
            // Sometimes the list is too long, so we need to scroll it a bit
            this.swipe(listRoot, SwipeDirection.UP);
        }
        return participantsList.getPeopleCount();
    }

    public boolean isParticipantVisible(String name) {
        return participantsList.isParticipantVisible(name);
    }

    public boolean isParticipantInvisible(String name) {
        return participantsList.isParticipantInvisible(name);
    }

    public boolean isTimedMessagesOptionVisible() {
        return timedMessageOptionCell.isDisplayed();
    }

    public boolean isTimedMessagesOptionInvisible() {
        return isElementInvisible(timedMessageOptionCell);
    }

    public boolean isReadReceiptsVisible() {
        return toggleReadReceipts.isDisplayed();
    }

    public boolean isReadReceiptsInvisible() {
        return isElementInvisible(toggleReadReceipts);
    }

    public boolean isLegalHoldIndicatorVisible() {
        return isElementVisible(legalHoldIndicator);
    }

    public boolean isLegalHoldIndicatorInvisible() {
        return isElementInvisible(legalHoldIndicator);
    }

    public void tapLegalHoldIndicator() {
        legalHoldIndicator.click();
    }

    public boolean isMembersSectionVisible() {
        return membersSection.isDisplayed();
    }

    public boolean isMembersSectionInvisible() {
        return isElementInvisible(membersSection);
    }

    public boolean isUserInAdminsSection(String userName) {
        return isLocatorDisplayed(classChainUserInAdminSection.apply(userName));
    }

    public boolean isUserNotInAdminsSection(String userName) {
        return isLocatorInvisible(classChainUserInAdminSection.apply(userName));
    }

    public boolean isSeeAllButtonVisibleInAdminsSection() {
        return isLocatorDisplayed(classChainShowAllInAdminSection);
    }

    public boolean isSeeAllButtonInvisibleInAdminsSection() {
        return isLocatorInvisible(classChainShowAllInAdminSection);
    }

    public void tapSeeAllButton() {
        seeAllButton.click();
    }
}
