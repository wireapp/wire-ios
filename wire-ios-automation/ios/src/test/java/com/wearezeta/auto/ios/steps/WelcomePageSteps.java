package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.misc.URLTransformer;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.WelcomePage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasItem;

public class WelcomePageSteps {

    IOSTestContext context;

    public WelcomePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private WelcomePage getWelcomePage() {
        return context.getPagesCollection().getPage(WelcomePage.class);
    }

    @Then("^I (do not )?see Welcome page$")
    public void iSeeWelcomePage(String doNot) {
        if (doNot == null) {
            assertThat("Wire Logo on Welcome page not visible.", getWelcomePage().isWireLogoVisible());
            assertThat("Welcome message on page is not visible.", getWelcomePage().isWelcomeMessageVisible());
        } else {
            assertThat("Welcome page is visible while it should not be.", getWelcomePage().isWelcomePageInvisible());
        }
    }

    @Then("I see domain name of backend on Welcome page")
    public void iSeeDomainName() {
        String domainName = URLTransformer.getHost(BackendConnections.getDefault().getBackendUrl());
        assertThat("Wrong or missing domain name on welcome page",
                getWelcomePage().getStaticTexts(), hasItem(containsString(domainName)));
    }

    @Then("^I see Enterprise Log In button on Welcome page$")
    public void iSeeEnterpriseLogInButtonOnWelcomePage() {
        assertThat("Enterprise Log In button is not visible.", getWelcomePage().isEnterpriseLogInButtonVisible());
    }

    @When("^I tap Login button on Welcome page$")
    public void iTapLoginButtonOnWelcomePage() {
        getWelcomePage().tapLoginButton();
    }

    @When("^I tap Create An Account button on Welcome page$")
    public void iTapCreateAnAccountButtonOnWelcomePage() {
        getWelcomePage().tapCreateAnAccountButton();
    }

    @When("^I tap Enterprise Login button on Welcome page$")
    public void iTapEnterpriseLoginButtonOnWelcomePage() {
        getWelcomePage().tapEnterpriseLoginButton();
    }
}