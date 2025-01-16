package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class UniqueUsernamePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "handleTextField")
    private WebElement input;

    @iOSXCUITFindBy(accessibility = "Save")
    private WebElement saveButton;

    public UniqueUsernamePage(WebDriver driver) {
        super(driver);
    }

    public void tapSaveButton() {
        saveButton.click();
    }

    public void inputStringInNameInput(String name) {
        input.clear();
        if (name.length() > 0) {
            input.sendKeys(name);
        }
    }

    public boolean isSaveButtonEnabled() {
        return saveButton.isEnabled();
    }
}
