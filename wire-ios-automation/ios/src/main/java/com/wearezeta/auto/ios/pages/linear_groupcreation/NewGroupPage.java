package com.wearezeta.auto.ios.pages.linear_groupcreation;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class NewGroupPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "NameField")
    private WebElement groupNameTextfield;

    @iOSXCUITFindBy(accessibility = "button.newgroup.next")
    private WebElement nextButton;

    @iOSXCUITFindBy(accessibility = "Go back to contact list")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "cell.groupdetails.options")
    private WebElement groupOptions;

    @iOSXCUITFindBy(accessibility = "toggle.newgroup.allowguests")
    private WebElement toggleAllowGuests;

    @iOSXCUITFindBy(accessibility = "toggle.newgroup.allowservices")
    private WebElement toggleAllowServices;

    @iOSXCUITFindBy(accessibility = "Protocol")
    private WebElement protocolOption;

    @iOSXCUITFindBy(accessibility = "Proteus (default)")
    private WebElement protocolButton;

    @iOSXCUITFindBy(accessibility = "MLS")
    private WebElement mlsOption;

    private static final String strToggleAllowGuests = "toggle.newgroup.allowguests";

    private static final Function<String, By> classChainToggle = toggleName -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCell[`name == '%s'`]/**/XCUIElementTypeSwitch", toggleName));

    private static final Function<String, By> classChainAllowGuestsByValue = value -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCell[`name == '%s'`]/**/XCUIElementTypeSwitch[`value == '%s'`]", strToggleAllowGuests, value));

    private static final Function<Integer, String> predicateStrMaxParticipantLimit = limit ->
            String.format("name CONTAINS 'Up to %s participants can join a group conversation'", limit);

    public NewGroupPage(WebDriver driver) {
        super(driver);
    }

    public void enterGroupName(String groupName) {
        groupNameTextfield.clear();
        groupNameTextfield.sendKeys(groupName);
    }

    public void tapNextButton(){
        nextButton.click();
    }
    public void tapBackButton(){
        backButton.click();
    }

    public boolean isExpectedConversationOptionsVisible(String text) {
        final By locator = MobileBy.AccessibilityId(text);
        return isLocatorDisplayed(locator);
    }

    public boolean isAllowGuestsEqualsTo(String expectedValue) {
        return isLocatorDisplayed(classChainAllowGuestsByValue.apply(expectedValue));
    }

    public void switchToggle() {
        getElement(classChainToggle.apply(strToggleAllowGuests)).click();
    }

    public boolean isProtocolVisible() {
        return protocolOption.isDisplayed();
    }

    public boolean isProtocolInvisible() {
        return isElementInvisible(protocolOption);
    }

    public boolean isProteusValueVisible() {
        return protocolButton.isDisplayed();
    }

    public boolean isProteusValueInvisible() {
        return isElementInvisible(protocolButton);
    }

    public boolean isMlsValueVisible() {
        return mlsOption.isDisplayed();
    }

    public boolean isMlsValueInvisible() {
        return isElementInvisible(mlsOption);
    }

    public void tapProtocolOption() {
        protocolButton.click();
    }

    public void tapMlsOption() {
        mlsOption.click();
    }

    public void tapConversationOptions() {
        groupOptions.click();
    }

    public boolean isMaxLimitEqualsTo(int expectedLimit) {
        return isLocatorDisplayed(MobileBy.iOSNsPredicateString(predicateStrMaxParticipantLimit.apply(expectedLimit)));
    }

    public boolean isGuestOptionVisible() {
        return toggleAllowGuests.isDisplayed();
    }

    public boolean isGuestOptionInvisible() {
        return isElementInvisible(toggleAllowGuests);
    }

    public boolean isServiceOptionVisible() {
        return toggleAllowServices.isDisplayed();
    }

    public boolean isServiceOptionInvisible() {
        return isElementInvisible(toggleAllowServices);
    }
}
