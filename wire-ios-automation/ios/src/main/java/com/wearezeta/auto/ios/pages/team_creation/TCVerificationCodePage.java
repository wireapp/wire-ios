package com.wearezeta.auto.ios.pages.team_creation;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.ios.pages.IOSPage;
import org.openqa.selenium.WebElement;

public class TCVerificationCodePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "VerificationCode")
    private WebElement emailCodeField;

    @iOSXCUITFindBy(accessibility = "resend_button")
    private WebElement resendButton;

    @iOSXCUITFindBy(accessibility = "Back")
    private WebElement backButton;

    public TCVerificationCodePage(WebDriver driver) {
        super(driver);
    }

    public void enterVerificationCode(String code) {
        emailCodeField.clear();
        emailCodeField.sendKeys(code);
    }

    public void tapResendCode(){
        resendButton.click();
    }

    public void tapBack(){
        backButton.click();
    }
}
