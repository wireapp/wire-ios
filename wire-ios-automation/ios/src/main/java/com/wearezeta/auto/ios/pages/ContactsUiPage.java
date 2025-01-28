package com.wearezeta.auto.ios.pages;

import java.util.function.Function;
import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import org.openqa.selenium.WebDriver;

public class ContactsUiPage extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'textViewSearch' AND visible == 1")
    private WebElement searchInput;

    @iOSXCUITFindBy(accessibility = "Invite Others")
    private WebElement inviteOthersButton;

    @iOSXCUITFindBy(accessibility = "Go back to conversation details")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "Back")
    private WebElement backButtonContactsUI;

    private static final Function<String, String> classChainStrConvoCellByName = name ->
            String.format("**/XCUIElementTypeCell[$type == 'XCUIElementTypeStaticText' AND label == '%s'$]", name);

    private static final Function<String, By> classChainOpenButtonByConvoName = name -> MobileBy.iOSClassChain(
            String.format("%s/XCUIElementTypeButton[`name == 'Open'`]", classChainStrConvoCellByName.apply(name)));

    public ContactsUiPage(WebDriver driver) {
        super(driver);
    }

    public boolean isSearchInputVisible() {
        return searchInput.isDisplayed();
    }

    public void inputTextToSearch(String text) {
        searchInput.click();
        searchInput.sendKeys(text);
    }

    public boolean isContactVisible(String contact) {
        final By locator = MobileBy.iOSClassChain(classChainStrConvoCellByName.apply(contact));
        return getDriver().findElement(locator).isDisplayed();
    }

    public void tapOpenButtonNextToUser(String contact) {
        final By locator = classChainOpenButtonByConvoName.apply(contact);
        getElement(locator).click();
        // Wait for animation
        isLocatorInvisible(locator, Timedelta.ofSeconds(5));
    }

    public boolean isInviteButtonVisible() {
        return inviteOthersButton.isDisplayed();
    }

    public void tapBackButton() {
        if (isElementVisible(backButton)){
        backButton.click();
        } else {
            backButtonContactsUI.click();
        }
    }

    public void tapInviteOthersButton() {
        inviteOthersButton.click();
    }

    public boolean isContactInvisible(String contact) {
        final By locator = MobileBy.iOSClassChain(classChainStrConvoCellByName.apply(contact));
        return isLocatorInvisible(locator);
    }
}
