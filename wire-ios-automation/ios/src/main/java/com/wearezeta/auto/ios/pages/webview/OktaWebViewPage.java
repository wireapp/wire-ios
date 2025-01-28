package com.wearezeta.auto.ios.pages.webview;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.IOSPage;
import org.openqa.selenium.WebElement;

public class OktaWebViewPage extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Username' AND name == 'Username' AND type == 'XCUIElementTypeOther'")
    private WebElement usernameField;

    @iOSXCUITFindBy(accessibility = "Password")
    private WebElement passwordField;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND name CONTAINS 'Sign In'")
    private WebElement signInButton;

    public OktaWebViewPage(WebDriver driver) {
        super(driver);
    }

    public boolean isOktaWebPageVisible() {
        return isElementVisible(usernameField, Timedelta.ofSeconds(20));
    }

    public boolean isOktaWebPageInvisible() {
        return isElementInvisible(usernameField);
    }

    public void setUsername(String login) {
        usernameField.click();
        usernameField.clear();
        usernameField.sendKeys(login);
    }

    public void setPassword(String password) {
        passwordField.click();
        passwordField.clear();
        passwordField.sendKeys(password);
    }

    public void tapSignInButton() {
        signInButton.click();
    }
}
