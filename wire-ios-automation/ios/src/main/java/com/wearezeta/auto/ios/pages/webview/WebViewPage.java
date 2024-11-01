package com.wearezeta.auto.ios.pages.webview;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class WebViewPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Done")
    private WebElement nameDoneButton;

    @iOSXCUITFindBy(accessibility = "Open")
    private WebElement openButton;

    @iOSXCUITFindBy(accessibility = "ShareButton")
    private WebElement safariShareButtonID;

    @iOSXCUITFindBy(accessibility = "More")
    private WebElement moreButtonShareExt;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Wire' AND name == 'Wire' AND value == 'Wire'")
    private WebElement idWireShareExt;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeCell[`name == \"Wire Bund\"`]/XCUIElementTypeOther/XCUIElementTypeImage")
    private WebElement idWireBundShareExt;

    @iOSXCUITFindBy(accessibility = "Choose")
    private WebElement idShareExtChoose;

    @iOSXCUITFindBy(accessibility = "Send")
    private WebElement idSendButton;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeSwitch' AND value == '0' AND name = 'Wire'")
    private WebElement wireSwitchOff;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeStaticText' AND name == 'Change Password'")
    private WebElement changePasswordButton;

    @iOSXCUITFindBy(accessibility = "Join in App")
    private WebElement joinInTheAppButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Address' AND name == 'URL'")
    private WebElement urlBar;

    @iOSXCUITFindBy(accessibility = "OpenInSafariButton")
    private WebElement openInSafariButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Done' AND name == 'Done'")
    private WebElement webViewDoneButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Address'")
    private WebElement tapURLLink;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Address' AND name == 'URL' AND type == 'XCUIElementTypeOther'")
    private WebElement tapURLLinkOnRealDevice;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Paste and Go'")
    private WebElement pasteURLLink;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Open in App' AND name == 'Open in App' AND value == 'Open in App'")
    private WebElement openiOSApp;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Download Wire' AND name == 'Download Wire' AND value == 'Download Wire'")
    private WebElement downloadApp;

    private static final Function<String, By> predicateText = value -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name CONTAINS '%s'", value));

    private static final Function<String, String> predicateStrAddressBarByUrlPart = urlPart ->
            String.format("(label == 'Address') AND value CONTAINS '%s'", urlPart);

    @iOSXCUITFindBy(accessibility = "unlock_screen.text_field.enter_passcode")
    private WebElement passcodeField;

    @iOSXCUITFindBy(accessibility = "unlock_screen.title.enter_passcode")
    private WebElement title;

    @iOSXCUITFindBy(accessibility = "unlock_screen.button.unlock")
    private WebElement unlockButton;

    private static final Timedelta VISIBILITY_TIMEOUT = Timedelta.ofSeconds(20);

    public WebViewPage(WebDriver driver) {
        super(driver);
    }

    public void closeWebView() {
        nameDoneButton.click();
    }

    public boolean isWebPageVisible(String expectedUrl) {
        return waitUntilElementVisible(getDriver().findElement(AppiumBy.iOSNsPredicateString(predicateStrAddressBarByUrlPart.apply(expectedUrl))));
    }
    
    public String getUrlFromUrlBar() {
        return urlBar.getText();
    }

    public boolean isChangePasswordPageVisible() {
        return isElementVisible(changePasswordButton, VISIBILITY_TIMEOUT);
    }

    public boolean isTextVisible(String expectedText) {
        return isLocatorExist(predicateText.apply(expectedText), Timedelta.ofSeconds(15));
    }

    public void tapShareButtonSafari() {
        safariShareButtonID.click();
    }

    public void tapMoreButonShareExt() {
        moreButtonShareExt.click();
    }

    public void enableWireShareExt() {
        if (isElementVisible(wireSwitchOff)){
            wireSwitchOff.click();
        }
    }

    public void tapOpenButton() {
        openButton.click();
    }

    public void tapDoneOnShareExt() {
        nameDoneButton.click();
    }

    public void tapWireInShareExt() {
        tapAtTheCenterOfElement(idWireShareExt);
    }

    public void tapWireBundInShareExt() {
        idWireBundShareExt.click();
    }

    public void tapChooseInShareExt() {
        waitUntilElementClickable(idShareExtChoose);
        idShareExtChoose.click();
    }

    public void selectConversationInShareExt(String name) {
        getDriver().findElement(MobileBy.AccessibilityId(name)).click();
    }

    public void tapSendButtonShareExt() {
        idSendButton.click();
    }

    public void inputPasscode(String passcode) {
        passcodeField.clear();
        passcodeField.sendKeys(passcode);
    }
    public boolean isUnlockWireInShareExtensionVisble() {
        return waitUntilElementVisible(title);
    }
    public void tapUnlockButtonOnShareExtension() {
        unlockButton.click();
    }

    public void tapJoinInTheAppButton() {
        waitUntilElementClickable(joinInTheAppButton);
        joinInTheAppButton.click();
    }

    public void iTapDoneOnWebView(){
        webViewDoneButton.click();
    }

    public void tapURLLinkSafari(){
        waitUntilElementVisible(tapURLLink);
        tapURLLink.click();
        longTapWithScript(tapURLLink);
    }

    public void tapURLLinkSafariRealDevice(){
        waitUntilElementVisible(tapURLLinkOnRealDevice);
        longTapWithScript(tapURLLinkOnRealDevice);
    }

    public void tapPasteURLLinkSafari(){
        waitUntilElementVisible(pasteURLLink);
        tapAtTheCenterOfElement(pasteURLLink);
    }

    public boolean goToiOSAppOnWebViewIsVisible() {
        return openiOSApp.isEnabled();
    }

    public boolean goToiOSAppOnWebViewIsInvisible() {
        return isElementInvisible(openiOSApp);
    }

    public void tapOnGoToiOSAppOnWireWebView() {
        tapAtTheCenterOfElement(openiOSApp);
    }

    public boolean downloadAppOnWebViewVisible() {
        return downloadApp.isEnabled();
    }

    public boolean downloadAppOnWebViewInvisible() {
        return isElementInvisible(downloadApp);
    }

    public void tapOnDownloadAppOnWebView() {
        tapAtTheCenterOfElement(downloadApp);
    }

    public void iTapOpenInSafarOnWebView(){
        openInSafariButton.click();
    }
}
