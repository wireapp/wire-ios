package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.backend.BackendConnections;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;

public class RegistrationPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "VerificationCode")
    private WebElement verificationCodeInput;

    @iOSXCUITFindBy(accessibility = "Accept")
    private WebElement acceptTOCButton;

    @iOSXCUITFindBy(accessibility = "resend_button")
    private WebElement resendCode;

    @iOSXCUITFindBy(accessibility = "ConfirmButton")
    private WebElement nameConfirmButton;

    @iOSXCUITFindBy(accessibility = "ConfirmButton")
    private WebElement usernameConfirmButton;

    @iOSXCUITFindBy(accessibility = "RevealButton")
    private WebElement passwordConfirmButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label IN {'Create an account'}")
    private WebElement registrationScreen;

    @iOSXCUITFindBy(accessibility = "NameField")
    private WebElement nameField;

    @iOSXCUITFindBy(accessibility = "EmailField")
    private WebElement emailField;

    @iOSXCUITFindBy(accessibility = "PasswordField")
    private WebElement passwordField;

    @iOSXCUITFindBy(accessibility = "UsernameField")
    private WebElement usernameField;

    @iOSXCUITFindBy(iOSNsPredicate = "value CONTAINS 'Enter the verification code we sent to'")
    private WebElement mailVerifyPrompt;

    @iOSXCUITFindBy(accessibility = "back")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "validation-rules")
    private WebElement passwordRulesDesc;

    @iOSXCUITFindBy(accessibility = "validation-failure")
    private WebElement passwordfailureMessage;

    public RegistrationPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return waitUntilElementVisible(registrationScreen);
    }

    public boolean isPasswordRulesVisible() {
        return isElementVisible(passwordRulesDesc, Timedelta.ofSeconds(1));
    }

    public boolean isPasswordFailureVisible() {
        return isElementVisible(passwordfailureMessage, Timedelta.ofSeconds(1));
    }

    public void inputActivationCode(ClientUser user) {
        waitUntilElementVisible(verificationCodeInput);
        verificationCodeInput.click();
        final String code = BackendConnections.get(user).getActivationCodeForEmail(user.getEmail());
        Actions a = new Actions(getDriver());
        a.sendKeys(code);
        a.perform();
    }

    public void clickAcceptTOCButton() {
        acceptTOCButton.click();
    }

    public void tapPasswordConfirmButton() {
        passwordConfirmButton.click();
    }

    public void tapNameConfirmButton() {
        nameConfirmButton.click();
    }

    public void tapUsernameConfirmButton() {
        usernameConfirmButton.click();
    }

    public void clearPasswordInput() {
        passwordField.clear();
    }

    public void typeEmail(String email) {
        waitUntilElementClickable(emailField);
        emailField.click();
        emailField.sendKeys(email);
    }

    public void typeName(String name) {
        waitUntilElementClickable(nameField);
        nameField.click();
        nameField.sendKeys(name);
    }

    public void typeUsername(String name) {
        waitUntilElementClickable(usernameField);
        usernameField.click();
        usernameField.sendKeys(name);
    }

    public void typePassword(String password) {
        passwordField.click();
        passwordField.sendKeys(password);
    }

    public boolean isEmailVerificationPromptVisible() {
        return waitUntilElementVisible(mailVerifyPrompt);
    }

    public void tapBackButton() {
        backButton.click();
    }
}
