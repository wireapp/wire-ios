package com.wearezeta.auto.ios.pages.webview;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class KeycloakWebViewPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeOther[`name == \"Sign in to Keycloak\"`]/XCUIElementTypeOther[2]/XCUIElementTypeTextField")
    private WebElement username;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeOther[`name == \"Sign in to Keycloak\"`]/XCUIElementTypeOther[3]/XCUIElementTypeSecureTextField")
    private WebElement password;

    @iOSXCUITFindBy(iOSNsPredicate = "name == \"Sign In\"")
    private WebElement signInButton;

    @iOSXCUITFindBy(accessibility = "Failed to retrieve certificate")
    private WebElement certificateError;

    @iOSXCUITFindBy(accessibility = "Ok")
    private WebElement ok;

    public KeycloakWebViewPage(WebDriver driver) {
        super(driver);
    }

    public void setUsername(String login) {
        username.click();
        username.clear();
        username.sendKeys(login);
    }

    public void setPassword(String password) {
        this.password.click();
        this.password.clear();
        this.password.sendKeys(password);
    }

    public void tapSignInButton() {
        signInButton.click();
    }

    public boolean isKeycloakWebPageVisible() {
        return isElementVisible(username, Timedelta.ofSeconds(20));
    }

    public boolean isKeycloakWebPageInvisible() {
        return isElementInvisible(username);
    }

    public boolean isCertificateErrorVisible() {
        return isElementVisible(certificateError);
    }
}
