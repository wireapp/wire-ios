package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import java.util.List;
import java.util.stream.Collectors;

public class WelcomePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "WireLogo")
    private WebElement wireLogo;

    @iOSXCUITFindBy(accessibility = "Trying to create a Pro or Enterprise account for your business or organization?")
    private WebElement welcomeMessage;

    @iOSXCUITFindBy(accessibility = "Create An Account")
    private WebElement createAnAccountBtn;

    @iOSXCUITFindBy(accessibility = "Log in")
    private WebElement logInBtn;

    @iOSXCUITFindBy(accessibility = "Enterprise Login")
    private WebElement enterpriseLogInBtn;

    @iOSXCUITFindBy(xpath = "//XCUIElementTypeStaticText")
    private List<WebElement> staticTextElements;

    public WelcomePage(WebDriver driver) {
        super(driver);
    }

    public boolean isWireLogoVisible() {
        return isElementVisible(wireLogo);
    }

    public boolean isWelcomeMessageVisible() {
        return welcomeMessage.isDisplayed();
    }

    public boolean isWelcomePageInvisible() {
        return isElementInvisible(wireLogo) && isElementInvisible(welcomeMessage);
    }

    public List<String> getStaticTexts() {
        return staticTextElements.stream().map(WebElement::getText).collect(Collectors.toList());
    }

    public boolean isEnterpriseLogInButtonVisible() {
        return enterpriseLogInBtn.isDisplayed();
    }

    public void tapLoginButton() {
        waitUntilElementClickable(logInBtn);
        logInBtn.click();
    }

    public void tapCreateAnAccountButton() {
        createAnAccountBtn.click();
    }

    public void tapEnterpriseLoginButton() {
        waitUntilElementClickable(enterpriseLogInBtn);
        enterpriseLogInBtn.click();
    }
}
