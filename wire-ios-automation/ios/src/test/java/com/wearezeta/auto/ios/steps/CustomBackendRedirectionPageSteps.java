package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.backend.Backend;
import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.CustomBackendRedirectionPage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.apache.commons.lang3.StringUtils;

import static org.hamcrest.MatcherAssert.assertThat;

public class CustomBackendRedirectionPageSteps {

    IOSTestContext context;

    public CustomBackendRedirectionPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CustomBackendRedirectionPage getCustomBackendRedirectionPage() {
        return context.getPagesCollection().getPage(CustomBackendRedirectionPage.class);
    }

    @Given("^I tap Proceed button on backend redirection page$")
    public void iTapProceedButtonOnBackendRedirectionPage() {
        getCustomBackendRedirectionPage().tapProceedButton();
    }

    @When("^I see redirection title on backend redirection page$")
    public void iSeeRedirectionTitleOnBackendRedirectionPage() {
        assertThat("Redirection title on redirection page is not visible while it should be.", getCustomBackendRedirectionPage().isRedirectionTitleVisible());
    }

    @Then("^I see backend information of backend (.*)$")
    public void iSeeBackendInformationOfBackend(String backendName) {
        Backend backend;
        if(backendName.equals("default")) {
            backend = BackendConnections.getDefault();
        } else {
            backend = BackendConnections.get(backendName);
        }
        String domainName = backend.getBackendName() + ".wire.link";
        assertThat("Wrong or missing domain name on redirection page",
                getCustomBackendRedirectionPage().isTextVisible(domainName));

        assertThat("Wrong or missing backend url on redirection page",
                getCustomBackendRedirectionPage().isTextVisible(StringUtils.chop(backend.getBackendUrl())));

        assertThat("Wrong or missing backend websocket url on redirection page",
                getCustomBackendRedirectionPage().isTextVisible(backend.getBackendWebsocket().replace("wss://", "https://")));
    }
}
