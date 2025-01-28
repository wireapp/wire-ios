package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.EncryptionAtRestOverlay;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class EncryptionAtRestOverlaySteps {
    IOSTestContext context;

    public EncryptionAtRestOverlaySteps(IOSTestContext context) {
        this.context = context;
    }

    private EncryptionAtRestOverlay getPage() {
        return context.getPagesCollection().getPage(EncryptionAtRestOverlay.class);
    }

    @Then("^I see Encryption At Rest overlay$")
    public void iSeeOverlay() {
        assertThat("Encryption at Rest overlay is not visible", getPage().isPasscodeOverlayVisible());
    }

    @Then("^I do not see Encryption At Rest overlay$")
    public void iDontSeeOverlay() {
        assertThat("Encryption At Rest overlay is shown", getPage().isPasscodeOverlayInvisible());
    }

    @When("^I confirm overlay if build has encryption at rest enabled$")
    public void iConfirm() {
        if (BackendConnections.getDefault().isFeatureEncryptionAtRestEnabled()) {
            // Currently not possible as on iOS 17 it is not possible to interact with the passcode overlay
            //            getPage().waitUntilPasscodeOverlayIsVisible();
            getPage().typePasscode("a");
            getPage().pressEnter();
        }
    }

    @When("^I type (.*) on the Encryption At Rest overlay input")
    public void ITypeOnOverlay(String input) {
        getPage().typePasscode(input);
    }

    @When("^I press enter on the Encryption At Rest overlay input")
    public void IPressEnterOnOverlay() {
        getPage().pressEnter();
    }

}
