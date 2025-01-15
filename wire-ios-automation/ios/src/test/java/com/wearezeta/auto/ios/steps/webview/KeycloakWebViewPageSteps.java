package com.wearezeta.auto.ios.steps.webview;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.webview.KeycloakWebViewPage;
import com.wearezeta.auto.ios.pages.webview.OktaWebViewPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.util.Map;
import java.util.Optional;
import java.util.Set;

import static org.hamcrest.MatcherAssert.assertThat;

public class KeycloakWebViewPageSteps {
    IOSTestContext context;

    public KeycloakWebViewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private KeycloakWebViewPage getPage() {
        return context.getPagesCollection().getPage(KeycloakWebViewPage.class);
    }

    @When("^I enter email (.*) on keycloak web view")
    public void WhenIHaveEnteredUsername(String email) {
        Timedelta.ofSeconds(1).sleep();
        email = context.getUsersManager()
                .replaceAliasesOccurrences(email, ClientUsersManager.FindBy.EMAIL_ALIAS);
        getPage().setUsername(email);
    }

    @When("^I login to keycloak as \"(.*)\"")
    public void WhenILoginOnKeycloak(String userAlias) {
        Timedelta.ofSeconds(1).sleep();
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        getPage().setUsername(user.getEmail());
        getPage().setPassword(user.getPassword());
        getPage().tapSignInButton();
    }

    @When("^I enter password (.*) on keycloak web view")
    public void WhenIHaveEnteredPassword(String password) {
        password = context.getUsersManager()
                .replaceAliasesOccurrences(password, ClientUsersManager.FindBy.PASSWORD_ALIAS);
        getPage().setPassword(password);
    }

    @Then("^I click sign in button on keycloak web view")
    public void iClickSignInButtonOnKeycloakWebView() {
        getPage().tapSignInButton();
    }

    @Then("^I (do not )?see keycloak web view$")
    public void ISeeOktaWebView(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The expected keycloak URL has not been opened in web browser",
                    getPage().isKeycloakWebPageVisible());
        } else {
            assertThat("The expected keycloak URL is opened in web browser",
                    getPage().isKeycloakWebPageInvisible());
        }
    }

    @Then("I see certificate error message")
    public void iSeeCertificateErrorMessage() {
        assertThat("The expected certificate error is not visible", getPage().isCertificateErrorVisible());
    }
}
