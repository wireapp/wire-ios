package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class GroupConnectedParticipantProfilePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "left_button")
    private WebElement leftActionButton;

    @iOSXCUITFindBy(accessibility = "Remove From Group…")
    private WebElement removeFromGroup;

    @iOSXCUITFindBy(accessibility = "Remove From Group")
    private WebElement confirmRemove;

    @iOSXCUITFindBy(accessibility = "right_button")
    private WebElement rightActionButton;

    @iOSXCUITFindBy(accessibility = "cell.profile.group_admin_options")
    private WebElement adminToggle;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'label.team_role' AND value = 'External'")
    private WebElement externalIcon;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'label.group_role' AND value == 'Group Admin'")
    private WebElement adminIcon;

    @iOSXCUITFindBy(accessibility = "Go back to conversation details")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "Back")
    private WebElement back;

    @iOSXCUITFindBy(accessibility = "Devices")
    private WebElement devicesTab;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'}")
    private WebElement nameLabel;

    private static final String strOpenConversationButton = "Open conversation";
    private static final String strConnectButton = "Connect";
    private Function<String, By> predicateLeftButtonByLabel = text ->
            MobileBy.iOSNsPredicateString(String.format("name == 'left_button' AND label == '%s'",text));

    private static final Function<String, By> predicateNameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value == '%s'",
                    name));

    public GroupConnectedParticipantProfilePage(WebDriver driver) {
        super(driver);
    }

    public void tapRemoveFromConversationButton() {
        rightActionButton.click();
    }

    public void tapOpenConversationButton() {
        leftActionButton.click();
    }

    public void tapBackButton() {
        if(isElementVisible(backButton)){
        backButton.click();
        } else {
            back.click();
        }
    }

    public void tapOpenMenuButton() {
        rightActionButton.click();
    }

    public boolean isOpenConversationButtonVisible() {
        return isLocatorDisplayed(predicateLeftButtonByLabel.apply(strOpenConversationButton));
    }

    public boolean isOpenConversationInvisible() {
        return isLocatorInvisible(predicateLeftButtonByLabel.apply(strOpenConversationButton));
    }

    public boolean isMoreActionsButtonVisible() {
        return isElementVisible(rightActionButton);
    }

    public boolean isMoreActionsButtonInvisible() { return isElementInvisible(rightActionButton);
    }

    public boolean isConnectButtonVisible() {
        return isLocatorDisplayed(predicateLeftButtonByLabel.apply(strConnectButton));
    }

    public boolean isConnectButtonInvisible() {
        return isLocatorInvisible(predicateLeftButtonByLabel.apply(strConnectButton));
    }

    public boolean isLeftActionButtonInvisible() {
        return isElementInvisible(leftActionButton);
    }

    public boolean isAdminToggleVisible() {
        return adminToggle.isDisplayed();
    }

    public boolean isAdminToggleInvisible() {
        return isElementInvisible(adminToggle);
    }

    public void tapAdminToggle() {
        adminToggle.click();
    }

    public boolean isAdminIconVisible() {
        return adminIcon.isDisplayed();
    }

    public boolean isAdminIconInvisible() {
        return isElementInvisible(adminIcon);
    }

    public boolean isExternalIconVisible() {
        return externalIcon.isDisplayed();
    }

    public boolean isExternalIconInvisible() {
        return isElementInvisible(externalIcon);
    }

    public boolean isUserDetailNameVisible(String expectedValue){
        return isLocatorDisplayed(predicateNameByValue.apply(expectedValue));
    }

    public boolean isUserDetailNameInvisible() {
        return isElementInvisible(nameLabel);
    }

    public void tapDevicesTab() {
        devicesTab.click();
    }

    public void confirmRemove() {
        removeFromGroup.click();
        confirmRemove.click();
    }
}
