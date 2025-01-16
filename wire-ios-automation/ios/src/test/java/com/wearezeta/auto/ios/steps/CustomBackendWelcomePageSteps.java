package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.CustomBackendWelcomePage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class CustomBackendWelcomePageSteps {

    IOSTestContext context;

    public CustomBackendWelcomePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CustomBackendWelcomePage getCustomBackendWelcomePage() {
        return context.getPagesCollection().getPage(CustomBackendWelcomePage.class);
    }

    @Then("^I see \"([^\"]*)\" label on Custom backend welcome page$")
    public void iSeeLabelOnCustomBackendWelcomePage(String backendName) {
        assertThat("Custom backend connection message is not visible.", getCustomBackendWelcomePage().isConnectionMessageVisible(backendName));
    }

    @When("^I tap Login with Email button on Custom backend welcome page$")
    public void iTapLoginWithEmailButtonOnCustomBackendWelcomePage() {
        getCustomBackendWelcomePage().tapOnLoginWithEmailButton();
    }

    @Given("^I see Custom backend welcome page for backend \"([^\"]*)\"$")
    public void iSeeCustomBackendWelcomePageForBackend(String backendName) {
        assertThat("Custom backend Welcome page is not visible", getCustomBackendWelcomePage().isTextVisible(backendName));
    }
}
