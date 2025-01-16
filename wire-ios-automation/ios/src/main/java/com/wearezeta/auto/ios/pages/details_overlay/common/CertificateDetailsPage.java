package com.wearezeta.auto.ios.pages.details_overlay.common;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class CertificateDetailsPage extends IOSPage {
  @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[`name == \"Show Certificate Details\"`]")
  private WebElement showCertificate;

  @iOSXCUITFindBy(accessibility = "CertificateDetailsView")
  private WebElement certificateDetails;

  public CertificateDetailsPage(WebDriver driver) {
    super(driver);
  }

  public void openCertificateDetails() {
    showCertificate.click();
  }

  public boolean isCertificateDetailsPageVisible() {
    return certificateDetails.isDisplayed();
  }

  public String getCertificate() { return certificateDetails.getText(); }
}
