package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.E2EIPage;
import io.cucumber.java.en.When;

public class E2EIOverlayPageSteps {

    IOSTestContext context;

    public E2EIOverlayPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private E2EIPage getE2EIPage() {
        return context.getPagesCollection().getPage(E2EIPage.class);
    }

    @When("^I tap Get Certificate button on Enrollment overlay$")
    public void iTapGetCertificateButtonOnE2EIPage() {
        getE2EIPage().tapGetCertificateButton();
    }

    @When("I click Ok on the Enrollment Success screen")
    public void iClickOkOnTheEnrollmentSuccessScreen() {
        getE2EIPage().tapOkButton();
    }
}