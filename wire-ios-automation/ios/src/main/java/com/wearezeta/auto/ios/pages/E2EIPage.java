package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class E2EIPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Get Certificate")
    private WebElement getCertificateBtn;

    @iOSXCUITFindBy(accessibility = "confirmationButton")
    private WebElement OkBtn;

    public E2EIPage(WebDriver driver) {
        super(driver);
    }

    public void tapGetCertificateButton() {
        waitUntilElementClickable(getCertificateBtn);
        getCertificateBtn.click();
    }

    public void tapOkButton() {
        OkBtn.click();
    }
}
