package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebElement;

import org.openqa.selenium.WebDriver;

import java.time.Duration;
import java.util.logging.Logger;

public class LoginPage extends IOSPage {

    Logger log = Logger.getLogger(LoginPage.class.getSimpleName());

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'Connect to server'")
    private WebElement connectToServerAlertTitle;

    @iOSXCUITFindBy(iOSNsPredicate = "name BEGINSWITH 'Open in \"Wire")
    private WebElement openInWireAlertTitle;

    @iOSXCUITFindBy(accessibility = "UseEmail")
    private WebElement switchToEmailLogin;

    @iOSXCUITFindBy(accessibility = "UsePhone")
    private WebElement switchToPhoneLogin;

    @iOSXCUITFindBy(accessibility = "Log in")
    private WebElement loginScreen;

    @iOSXCUITFindBy(accessibility = "restore_backup")
    private WebElement restoreButtonOnFirstTimeOverlay;

    @iOSXCUITFindBy(accessibility = "Log In")
    private WebElement logInButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Log In' AND name == 'Log In' AND type == 'XCUIElementTypeButton'")
    private WebElement invinsibleLoginButton;

    @iOSXCUITFindBy(accessibility = "companyLoginButton")
    private WebElement companyLoginButton;

    @iOSXCUITFindBy(accessibility = "EmailField")
    private WebElement emailField;

    @iOSXCUITFindBy(accessibility = "PasswordField")
    private WebElement passwordField;

    @iOSXCUITFindBy(accessibility = "back")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "bottomBarSettingsButton")
    private WebElement profileButton;

    public LoginPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return isElementVisible(loginScreen);
    }

    public void acceptConnectToServerAlert() {
        if (waitUntilElementVisible(connectToServerAlertTitle)) {
            getDriver().switchTo().alert().accept();
        } else {
            throw new TimeoutException("Alert to connect to server did not appear");
        }

    }

    public void acceptOpenInWireAlert() {
        // We currently have no clue when this alert is shown.
        // it is indeterministic so we wait for 1 second without implicit waits and timeouts.
        if (!waitUntilElementInvisible(openInWireAlertTitle, Duration.ofSeconds(1))) {
            getDriver().switchTo().alert().accept();
        }
    }

    public void switchToEmailLogin() {
        if(isElementVisible(switchToEmailLogin)){
            switchToEmailLogin.click();
        }
    }

    public boolean isPhoneLoginVisible() {
        return switchToPhoneLogin.isDisplayed();
    }

    public boolean isPhoneLoginInvisible() {
        return isElementInvisible(switchToPhoneLogin);
    }

    public boolean waitForLoginProperly() {
        log.info("Start wait for login...");
        boolean noLoginForm = waitUntilElementInvisible(loginScreen);
        log.info("noLoginForm: " + noLoginForm);
        boolean noFirstTimeOverlay = waitUntilElementInvisible(restoreButtonOnFirstTimeOverlay);
        log.info("noFirstTimeOverlay: " + noFirstTimeOverlay);
        boolean profileButtonShown = waitUntilElementVisible(profileButton);
        return noLoginForm && noFirstTimeOverlay && profileButtonShown;
    }

    public void tapLoginButton() {
        logInButton.click();
    }

    public boolean isLoginButtonInvisible() {
        return isElementVisible(invinsibleLoginButton, LOGIN_TIMEOUT);
    }

    public void setLogin(String login) {
        waitUntilElementClickable(emailField);
        emailField.click();
        emailField.clear();
        emailField.sendKeys(login);
    }

    public void setPassword(String password) {
        passwordField.click();
        passwordField.clear();
        passwordField.sendKeys(password);
    }

    private static final Timedelta LOGIN_TIMEOUT = Timedelta.ofSeconds(30);

    public void tapBackButton() {
        if (backButton.isDisplayed()) {
            backButton.click();
        }
    }

    public boolean isCompanyLoginButtonInvisible() {
        return isElementInvisible(companyLoginButton, Timedelta.ofSeconds(1));
    }

    public void loginAs(String email, String password) {
        setLogin(email);
        setPassword(password);
        tapLoginButton();
    }
}
