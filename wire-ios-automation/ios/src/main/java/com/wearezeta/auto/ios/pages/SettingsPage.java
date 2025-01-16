package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.backend.models.AccentColor;
import com.wearezeta.auto.common.log.ZetaLogger;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.*;
import org.openqa.selenium.support.ui.ExpectedCondition;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.awt.image.BufferedImage;
import java.time.Duration;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.logging.Logger;

public class SettingsPage extends IOSPage {

    private static final Logger log = ZetaLogger.getLog(SettingsPage.class.getSimpleName());

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement xButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Advanced\"`]")
    private WebElement advanced;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Devices'")
    private WebElement devicesItem;

    @iOSXCUITFindBy(iOSNsPredicate = "label CONTAINS 'This makes audio calls use less data and work better on slower networks. Turn off to use constant bitrate encoding (CBR). This setting only affects 1:1 calls; conference calls always use CBR encoding.'")
    private WebElement vbrText;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Account'")
    private WebElement accountItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Back Up Conversations'")
    private WebElement backUpConversationsItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Options'")
    private WebElement optionsItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Log Out'")
    private WebElement logOutItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Profile Picture'")
    private WebElement pictureItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Reset Password'")
    private WebElement resetPasswordItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Support'")
    private WebElement supportItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Wire Support Website'")
    private WebElement wireSupportWebsiteItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Delete Account'")
    private WebElement deleteAccountItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Username'")
    private WebElement usernameItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Email'")
    private WebElement emailItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Name'")
    private WebElement nameItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'About'")
    private WebElement aboutItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND label == 'Profile Color'")
    private WebElement colorItem;

    @iOSXCUITFindBy(accessibility = "Purple")
    private WebElement colorPurple;

    @iOSXCUITFindBy(accessibility = "DomainFieldDisabled")
    private WebElement nonEditableDomainLabel;

    @iOSXCUITFindBy(accessibility = "TeamFieldDisabled")
    private WebElement nonEditableTeamLabel;

    @iOSXCUITFindBy(accessibility = "Terms of Use")
    private WebElement termsOfUseItem;

    @iOSXCUITFindBy(accessibility = "Privacy Policy")
    private WebElement privacyPolicyItem;

    @iOSXCUITFindBy(accessibility = "Wire Website")
    private WebElement wireWebsiteItem;

    @iOSXCUITFindBy(accessibility = "Contact Support")
    private WebElement contactSupportItem;

    @iOSXCUITFindBy(accessibility = "Report Misuse")
    private WebElement reportMisuse;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeTable' AND visible == 1")
    private WebElement predicateOptionsRoot;

    private static final Function<String, String> classChainStrMenuItemByName = name ->
            String.format("**/XCUIElementTypeCell[$type == 'XCUIElementTypeStaticText' AND label == '%s'$]", name);

    private static final BiFunction<String, String, String> classChainStrSettingsValue =
            (itemName, expectedValue) -> String.format("%s/*[`value == '%s'`]",
                    classChainStrMenuItemByName.apply(itemName), expectedValue);

    private static final By classChainSelfNameEditField =
            MobileBy.iOSClassChain(String.format("%s/XCUIElementTypeTextField[-1]",
                    classChainStrMenuItemByName.apply("Name")));

    private static final String xpathStrColorPicker = "//*[@name='COLOR']/following::XCUIElementTypeTable[1]";
    private static final By xpathColorPicker = By.xpath(xpathStrColorPicker);

    // indexation starts from 1
    private static final Function<Integer, String> xpathSreColorByIdx = idx ->
            String.format("%s/XCUIElementTypeCell[%s]", xpathStrColorPicker, idx);

    private static final Function<String, By> predicateStrUniqueUsernameInSettings = name -> MobileBy.iOSNsPredicateString(
            //FIXME: waiting for correct Id from Alexis String.format("name == 'UsernameFieldDisabled' OR name == 'UsernameField' AND value ='%s'", name));
            String.format("value ='@%s'", name));

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeImage' AND name == 'imagePreview' AND value == 'image'")
    private WebElement predicateSettingsProfilePicturePreview;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeImage' AND name == 'imagePreview' AND value == 'color'")
    private WebElement predicateSettingsProfileColorPreview;

    @iOSXCUITFindBy(xpath = "//XCUIElementTypeStaticText[@name='COLOR']/preceding-sibling::XCUIElementTypeButton")
    private WebElement xpathColorPickerCloseButton;

    @iOSXCUITFindBy(accessibility = "EmailField")
    private WebElement nameEmailInput;

    @iOSXCUITFindBy(accessibility = "Verify email")
    private WebElement nameVerifyEmailTitle;

    @iOSXCUITFindBy(accessibility = "Account")
    WebElement accountBackButton;

    @iOSXCUITFindBy(accessibility = "Settings")
    WebElement settingsBackButton;

    private static final Function<String, By> predicateNavigationButtonByName = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeButton' AND name =[c] '%s'", name));

    private static final Function<String, By> predicateDomainName = name -> MobileBy.iOSNsPredicateString(
            String.format("name == 'DomainFieldDisabled' AND value == '%s'", name));

    private static final Function<String, By> predicateTeamName = name -> MobileBy.iOSNsPredicateString(
            String.format("name == 'TeamFieldDisabled' AND value == '%s'", name));

    private static final Function<String, By> predicateDomainNameOnUsernameUI = name -> MobileBy.iOSNsPredicateString(
            String.format("label == '%s'", name));

    private static final Function<String, By> predicateNonEditableDomainNameOnUsernameUI = name -> MobileBy.iOSNsPredicateString(
            String.format("label == '%s' AND type == 'XCUIElementTypeStaticText'", name));
    @iOSXCUITFindBy(accessibility = "ReadReceiptsSwitch")
    private WebElement nameReadReceiptToggle;

    @iOSXCUITFindBy(accessibility = "Appearance")
    private WebElement nameAppearanceText;

    @iOSXCUITFindBy(accessibility = "nameProfilePictureLabel")
    private WebElement nameProfilePictureLabel;

    @iOSXCUITFindBy(accessibility = "Color")
    private WebElement nameColorLabel;

    @iOSXCUITFindBy(accessibility = "NameFieldDisabled")
    private WebElement nameDisplayNameDisabled;

    @iOSXCUITFindBy(accessibility = "UsernameFieldDisabled")
    private WebElement nameUniqueUsernameDisabled;

    @iOSXCUITFindBy(accessibility = "handleTextField")
    private WebElement nameUserName;

    @iOSXCUITFindBy(accessibility = "Beta Program")
    private WebElement nameBetaProgram;

    @iOSXCUITFindBy(accessibility = "Beta Toggle")
    private WebElement nameBetaToggle;

    private static final Function<Integer, By> predicateBetaToggleValue = value -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeSwitch' AND name == '%s' AND value == '%s'", "Beta Toggle", value));

    public SettingsPage(WebDriver driver) {
        super(driver);
    }

    private WebElement scrollToItem(String itemName) {
        By locator = MobileBy.iOSClassChain(classChainStrMenuItemByName.apply(itemName));
        return new WebDriverWait(getDriver(), Duration.ofSeconds(getDefaultLookupTimeoutSeconds()))
                .ignoring(StaleElementReferenceException.class)
                .ignoring(NoSuchElementException.class)
                .until(locatorIsScrolledIntoView(locator));
    }

    private WebElement scrollToItem(WebElement item) {
        return new WebDriverWait(getDriver(), Duration.ofSeconds(getDefaultLookupTimeoutSeconds()))
                .ignoring(StaleElementReferenceException.class)
                .ignoring(NoSuchElementException.class)
                .until(elementIsScrolledIntoView(item));
    }

    private ExpectedCondition<WebElement> elementIsScrolledIntoView(final WebElement element) {
        return driver -> {
            if (element.isDisplayed()) {
                return element;
            }
            log.info("Scroll up");
            swipe(predicateOptionsRoot, SwipeDirection.UP);
            return null;
        };
    }

    private ExpectedCondition<WebElement> locatorIsScrolledIntoView(final By locator) {
        return driver -> {
            WebElement element = getDriver().findElement(locator);
            if (element.isDisplayed()) {
                return element;
            }
            log.info("Scroll up");
            swipe(predicateOptionsRoot, SwipeDirection.UP);
            return null;
        };
    }

    public void tapAccount() {
        waitUntilElementClickable(accountItem);
        accountItem.click();
    }

    public void tapDevices() {
        devicesItem.click();
    }

    public void tapBackUpConversations() {
        scrollToItem(backUpConversationsItem).click();
    }

    public void tapOptionsItem() {
        waitUntilElementClickable(optionsItem);
        optionsItem.click();
    }

    public void tapLogOutItem() {
        scrollToItem(logOutItem).click();
    }

    public void tapPictureItem() {
        pictureItem.click();
    }

    public void tapResetPasswordItem() {
        scrollToItem(resetPasswordItem);
        resetPasswordItem.click();
    }

    public void tapSupportItem() {
        supportItem.click();
    }

    public void tapWireSupportWebsiteItem() {
        wireSupportWebsiteItem.click();
    }

    public void tapDeleteAccountItem() {
        scrollToItem(deleteAccountItem).click();
    }

    public void tapUsernameItem() {
        usernameItem.click();
    }

    public void tapEmailItem() {
        emailItem.click();
    }

    public void tapNameItem() {
        nameItem.click();
    }

    public void tapAboutItem() {
        aboutItem.click();
    }

    public void tapColorItem() {
        scrollToItem(colorItem).click();
    }

    public void tapColorPurple() {
        colorPurple.click();
    }

    public boolean isItemVisible(String itemName) {
        return scrollToItem(itemName).isDisplayed();
    }

    public boolean isItemInvisible(String itemName) {
        try {
            scrollToItem(itemName);
        } catch (Exception e) {
            return true;
        }
        return isLocatorInvisible(MobileBy.iOSClassChain(classChainStrMenuItemByName.apply(itemName)));
    }

    public void tapX() {
        xButton.click();
    }

    public void tapNavigationButton(String name) {
        getDriver().findElement(predicateNavigationButtonByName.apply(name)).click();
    }

    public boolean isSettingItemValueEqualTo(String itemName, String expectedValue) {
        final By locator = MobileBy.iOSClassChain(classChainStrSettingsValue.apply(itemName, expectedValue));
        return waitUntilLocatorVisible(locator);
    }

    public WebElement clearSelfName() {
        final WebElement selfName = getElementIfExists(classChainSelfNameEditField).orElseThrow(
                () -> new IllegalStateException("Name input is not present on the page")
        );
        selfName.clear();
        return selfName;
    }

    public void clearUsername() {
        nameUserName.clear();
    }

    public void setSelfName(String newName) {
        clearSelfName().sendKeys(newName);
    }

    public BufferedImage getColorPickerStateScreenshot() {
        return this.getElementScreenshot(getDriver().findElement(xpathColorPicker)).orElseThrow(
                () -> new IllegalStateException("Cannot make a screenshot of Color Picker control")
        );
    }

    public void closeColorPicker() {
        xpathColorPickerCloseButton.click();
    }

    public void selectAccentColor(AccentColor byName) {
        final By locator = By.xpath(xpathSreColorByIdx.apply(byName.getId()));
        getDriver().findElement(locator).click();
    }

    public boolean isUniqueUsernameInSettingsDisplayed(String uniqueName) {
        return waitUntilLocatorVisible(predicateStrUniqueUsernameInSettings.apply(uniqueName));
    }

    public boolean isProfilePicturePreviewInvisible() {
        return waitUntilElementInvisible(predicateSettingsProfilePicturePreview);
    }

    public void changeEmailAddress(String newEmail) {
        nameEmailInput.clear();
        nameEmailInput.sendKeys(newEmail);
    }

    public boolean waitUntilEmailVerificationHappens(Duration timeout) {
        return waitUntilElementInvisible(nameVerifyEmailTitle, timeout);
    }

    public boolean iSeeVBRText() {
        return vbrText.isDisplayed();
    }

    public void switchToggleReadReceipts() {
        nameReadReceiptToggle.click();
    }

    public boolean isDisplayNameInputFieldStatic() {
        return isElementVisible(nameDisplayNameDisabled);
    }

    public boolean isUniqueUsernameInputFieldStatic() {
        return isElementVisible(nameUniqueUsernameDisabled);
    }

    public boolean isAppearanceSectionInvisible() {
        return waitUntilElementInvisible(nameAppearanceText) && isProfilePictureInvisible() && isAccentColorInvisible();
    }

    public boolean isProfilePictureInvisible() {
        return waitUntilElementInvisible(nameProfilePictureLabel) && isProfilePicturePreviewInvisible();
    }
    public boolean isAccentColorInvisible() {
        return waitUntilElementInvisible(nameColorLabel) && waitUntilElementInvisible(predicateSettingsProfileColorPreview);
    }

    public boolean isBetaToggleVisible() {
        return isElementVisible(nameBetaProgram);
    }

    public boolean isBetaToggleInvisible() {
        return waitUntilElementInvisible(nameBetaProgram);
    }

    public boolean isBetaToggleChecked() {
        return waitUntilLocatorVisible(predicateBetaToggleValue.apply(1));
    }

    public boolean isBetaToggleUnchecked() {
        return waitUntilLocatorVisible(predicateBetaToggleValue.apply(0));
    }

    public void tapBetaToggle() {
        nameBetaToggle.click();
    }

    public boolean isDomainNameVisible(String domainName) {
        final By locator = predicateDomainName.apply(domainName);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isDomainNameVisibleOnUsernameUI(String domainName) {
        final By locator = predicateDomainNameOnUsernameUI.apply(domainName);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isNonEditableDomainNameFieldOnUsernameUI(String domainName) {
        final By locator = predicateNonEditableDomainNameOnUsernameUI.apply(domainName);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isDomainNonEditableOnSettings() {
        return !nonEditableDomainLabel.isEnabled();
    }

    public boolean isTeamNonEditableOnSettings() {
        return !nonEditableTeamLabel.isEnabled();
    }

    public boolean isTeamNameVisible(String domainName) {
        final By locator = predicateTeamName.apply(domainName);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isTeamNameInvisible(String domainName) {
        final By locator = predicateTeamName.apply(domainName);
        return isLocatorInvisible(locator);
    }

    public void tapTermsOfUse(){ termsOfUseItem.click();}

    public void tapPrivacyPolicy(){ privacyPolicyItem.click();}

    public void tapWireWebsite(){ wireWebsiteItem.click();}

    public void tapContactSupport(){ contactSupportItem.click();}

    public void tapReportMisuse(){ reportMisuse.click();}

    public void tapAdvanced() {
        advanced.click();
    }

    public void tapAccountBackButton() {
        accountBackButton.click();
    }
    public void tapSettingsBackButton() {
        settingsBackButton.click();
    }
}