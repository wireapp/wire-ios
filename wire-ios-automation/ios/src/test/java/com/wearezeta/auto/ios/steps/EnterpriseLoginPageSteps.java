package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.EnterpriseLoginPage;
import io.cucumber.java.en.Then;
import static org.hamcrest.MatcherAssert.assertThat;

public class EnterpriseLoginPageSteps {
    IOSTestContext context;

    public EnterpriseLoginPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private EnterpriseLoginPage getEnterpriseLoginPage() {
        return context.getPagesCollection().getPage(EnterpriseLoginPage.class);
    }

    @Then("^I (do not )?see Enterprise Login popup$")
    public void iSeeEnterpriseLoginDialogueBox(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Enterprise Log In dialogue box is not visible.", getEnterpriseLoginPage().isEnterpriseLoginBoxVisible());
        } else {
            assertThat("Enterprise Log In dialogue box is visible.", getEnterpriseLoginPage().isEnterpriseLoginBoxInvisible());
        }
    }

    @Then("^I see Enterprise Login popup contains text \"([^\"]*)\"$")
    public void iSeeDialogueBoxContainsText(String alertText) {
        assertThat("Enterprise login popup doesn't contain expected text.", getEnterpriseLoginPage().isAlertContainsText(alertText));
    }

    @Then("^I see Enterprise Login popup contains button Cancel$")
    public void iSeeDialogueBoxContainsOptionCancel() {
        assertThat("Cancel option is not present on the Enterprise Log In popup.", getEnterpriseLoginPage().isCancelOptionVisible());
    }

    @Then("^I type \"([^\"]*)\" into EmailSSO code field$")
    public void iTypeCodeIntoSSOCodeField(String code) {
        if (code.equals("default")) {
            code = context.getCommonSteps().getSSOCode();
        }
        getEnterpriseLoginPage().typeCodeIntoEmailSSOField(code);
    }

    @Then("^I see error message \"([^\"]*)\" on Enterprise Login popup$")
    public void iSeeTheErrorMessage(String expectedText) {
        assertThat("Actual error message is not same as expected.", getEnterpriseLoginPage().isAlertContainsText(expectedText));
    }
}