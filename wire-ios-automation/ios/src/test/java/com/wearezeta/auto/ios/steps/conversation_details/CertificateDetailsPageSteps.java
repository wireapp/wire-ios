package com.wearezeta.auto.ios.steps.conversation_details;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.common.CertificateDetailsPage;
import static org.hamcrest.MatcherAssert.assertThat;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

public class CertificateDetailsPageSteps {
  IOSTestContext context;

  public CertificateDetailsPageSteps(IOSTestContext context) {
    this.context = context;
  }

  private CertificateDetailsPage getCertificateDetailsPage()  {
    return context.getPagesCollection().getPage(CertificateDetailsPage.class);
  }

  @When("I open my certificate details")
  public void iOpenMyCertificateDetails() {
    getCertificateDetailsPage().openCertificateDetails();
  }

  @Then("I see certificate details info")
  public void iSeeCertificateDetailsInfo() {
    assertThat("Certificate details not visible", getCertificateDetailsPage().isCertificateDetailsPageVisible());
  }

  @When("I copy my certificate details")
  public void iCopyMyCertificateDetails() {
    context.setRememberedCertificate(getCertificateDetailsPage().getCertificate());
  }
}
