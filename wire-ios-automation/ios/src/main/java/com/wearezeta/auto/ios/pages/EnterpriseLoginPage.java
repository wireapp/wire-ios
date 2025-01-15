package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class EnterpriseLoginPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "textfield.sso.code")
    private WebElement emailSSOCodeTextField;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeAlert' AND name == 'Enterprise Login'")
    private WebElement predicateEnterpriseLogInPopup;

    public EnterpriseLoginPage(WebDriver driver) {
        super(driver);
    }

    public void typeCodeIntoEmailSSOField(String code) {
        emailSSOCodeTextField.sendKeys(code);
    }

    public boolean isEnterpriseLoginBoxVisible() {
        return predicateEnterpriseLogInPopup.isDisplayed();
    }

    public boolean isEnterpriseLoginBoxInvisible() {
        return isElementInvisible(predicateEnterpriseLogInPopup);
    }

    public boolean isCancelOptionVisible() {
        return isAlertButtonVisible("Cancel");
    }
}
