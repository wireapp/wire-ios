package com.wearezeta.auto.ios.steps.webview;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.webview.WebViewPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;

public class WebViewSteps {
    IOSTestContext context;

    public WebViewSteps(IOSTestContext context) {
        this.context = context;
    }

    private WebViewPage getPage() {
        return context.getPagesCollection().getPage(WebViewPage.class);
    }

    @When("^I close the web view$")
    public void iCloseWebView() {
        getPage().closeWebView();
    }

    @Then("^I see \"(.*)\" web page opened$")
    public void ISeeWebPage(String expectedUrl) {
        assertThat(String.format("The expected URL '%s' has not been opened in web browser", expectedUrl),
                getPage().isWebPageVisible(expectedUrl));
    }

    @Then("^I see \"(.*)\" in url bar of web page opened$")
    public void iSeeWebPageUrl(String expectedUrl) {
        assertThat("Wrong URL", getPage().getUrlFromUrlBar(), containsString(expectedUrl));
    }

    @Then("^I do not see \"(.*)\" in url bar of web page opened$")
    public void iDoNotSeeWebPageUrl(String expectedUrl) {
        assertThat("Wrong URL", getPage().getUrlFromUrlBar(), not(containsString(expectedUrl)));
    }

    @Then("I see text element \"(.*)\" on web page")
    public void ISeeTextElement(String expectedText) {
        assertThat(String.format("Expected text element '%s' was not found on web page", expectedText),
            getPage().isTextVisible(expectedText));
    }

    @Then("^I see \"Change Password\" web page$")
    public void ISeeChangePasswordPage() {
        assertThat("Change Password button is not shown", getPage().isChangePasswordPageVisible());
    }

    @When("^I tap Share button in Safari$")
    public void iTapShareInSafari() {
        getPage().tapShareButtonSafari();
    }

    @When("^I tap Join in the app button in Safari$")
    public void iTapJoinInTheAppButton() {
        getPage().tapJoinInTheAppButton();
    }

    @When("^I tap More button on share extension$")
    public void iTapMoreButtonShareExt() {
        getPage().tapMoreButonShareExt();
    }

    @When("^I enable Wire in share extension$")
    public void iEnableWireShareExt() {
        getPage().enableWireShareExt();
    }

    @When("^I tap Done in share extension$")
    public void iTapDoneInShareExt() {
        getPage().tapDoneOnShareExt();
    }

    @When("^I tap Wire in share extension$")
    public void iTapWireInShareExt() {
        getPage().tapWireInShareExt();
    }

    @When("^I tap Wire Column in share extension$")
    public void iTapWireColumnInShareExt() {
        getPage().tapWireColumnInShareExt();
    }

    @When("^I tap Choose in share extension$")
    public void iTapChooseInShareExt() {
        getPage().tapChooseInShareExt();
    }

    @When("^I select conversation \"(.*)\" in share extension$")
    public void iTapChooseInShareExt(String conversationName) {
        conversationName = context.getUsersManager()
                .replaceAliasesOccurrences(conversationName, ClientUsersManager.FindBy.NAME_ALIAS);
        getPage().selectConversationInShareExt(conversationName);
    }

    @When("^I tap Send button in share extension$")
    public void iTapSendInShareExt() {
        getPage().tapSendButtonShareExt();
    }

    @When("I enter passcode (.*) on unlock screen in share extension$")
    public void iEnterPassCode(String passcode) {
        getPage().inputPasscode(passcode);
    }

    @And("^I see Unlock wire in share extension$")
    public void iSeeOverlay() {
        assertThat("unlock wire in share extension is not visible", getPage().isUnlockWireInShareExtensionVisble());
    }

    @When("^I press unlock on share extension screen$")
    public void iPressUnlock() {
        getPage().tapUnlockButtonOnShareExtension();
    }

    @When("^I tap Done Button on web view$")
    public void iTapDoneOnWebView() {
        getPage().iTapDoneOnWebView();
    }

    @When("^I tap URL on safari view$")
    public void iTapURLSafari() {
        getPage().tapURLLinkSafari();
    }

    @When("^I tap URL on safari view on real device$")
    public void iTapURLSafariRealDevice() {
        getPage().tapURLLinkSafariRealDevice();
    }

    @When("^I tap paste on safari view$")
    public void iTapPasteURLSafari() {
        getPage().tapPasteURLLinkSafari();
    }

    @Then("^I (do not )?see open in iOS app on wire web view$")
    public void iSeeOpenApp(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Open iOS App button is not visible", getPage().goToiOSAppOnWebViewIsVisible());
        } else {
            assertThat("Open iOS App button is visible", getPage().goToiOSAppOnWebViewIsInvisible());
        }
    }

    @When("^I tap Open in iOS App on wire web view$")
    public void iTapOpenApp() {
        getPage().tapOnGoToiOSAppOnWireWebView();
    }

    @Then("^I (do not )?see download app on wire web view$")
    public void iSeeDownloadApp(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Download iOS App button is not visible", getPage().downloadAppOnWebViewVisible());
        } else {
            assertThat("Download iOS App button is visible", getPage().downloadAppOnWebViewInvisible());
        }
    }

    @When("^I tap Download App on wire web view$")
    public void iTapDownloadApp() {
        getPage().tapOnDownloadAppOnWebView();
    }
    @When("^I tap Open in Safari Button on web view$")
    public void iTapOpenInSafari() {
        getPage().iTapOpenInSafarOnWebView();
    }
}
