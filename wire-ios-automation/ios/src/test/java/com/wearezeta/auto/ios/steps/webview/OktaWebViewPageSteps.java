package com.wearezeta.auto.ios.steps.webview;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.webview.OktaWebViewPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class OktaWebViewPageSteps {
    IOSTestContext context;

    public OktaWebViewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private OktaWebViewPage getPage() {
        return context.getPagesCollection().getPage(OktaWebViewPage.class);
    }

    @Then("^I (do not )?see okta web view$")
    public void ISeeOktaWebView(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The expected okta URL has not been opened in web browser",
                    getPage().isOktaWebPageVisible());
        } else {
            assertThat("The expected okta URL is opened in web browser",
                    getPage().isOktaWebPageInvisible());
        }
    }

    @When("^I enter user name (.*) on okta web view")
    public void WhenIHaveEnteredUsername(String username) {
        username = context.getUsersManager()
                .replaceAliasesOccurrences(username, ClientUsersManager.FindBy.EMAIL_ALIAS);
        getPage().setUsername(username);
    }

    @When("^I enter password (.*) on okta web view")
    public void WhenIHaveEnteredPassword(String password) {
        password = context.getUsersManager()
                .replaceAliasesOccurrences(password, ClientUsersManager.FindBy.PASSWORD_ALIAS);
        getPage().setPassword(password);
    }

    @Then("^I click sign in button on okta web view")
    public void iClickSignInButtonOnOktaWebView() {
        getPage().tapSignInButton();
    }
}
