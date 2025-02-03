package com.wearezeta.auto.ios.pages.team_creation;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.ios.pages.IOSPage;
import org.openqa.selenium.WebElement;

public class InvitePeoplePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "EmailInputField")
    private WebElement enterEmailField;

    @iOSXCUITFindBy(accessibility = "button.addpeople.create")
    private WebElement doneButton;

    public InvitePeoplePage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return isElementVisible(enterEmailField);
    }

    public void tapDoneButton(){
        doneButton.click();
    }
}
