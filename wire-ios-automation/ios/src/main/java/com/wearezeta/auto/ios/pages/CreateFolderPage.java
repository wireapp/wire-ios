package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.log.ZetaLogger;
import java.util.logging.Logger;
import org.openqa.selenium.WebElement;

public class CreateFolderPage extends IOSPage {
    public CreateFolderPage(WebDriver driver) {
        super(driver);
    }

    @iOSXCUITFindBy(accessibility = "Create New Folder")
    private WebElement createNewFolderTitle;

    @iOSXCUITFindBy(accessibility = "textfield.newfolder.name")
    private WebElement folderNameTextField;

    @iOSXCUITFindBy(accessibility = "button.newfolder.create")
    private WebElement createButton;

    @iOSXCUITFindBy(accessibility = "back")
    private WebElement backButton;

    public boolean isVisible() {
        return isElementVisible(createNewFolderTitle);
    }

    public void tapBackButton() {
        backButton.click();
    }

    public void tapCreateButton() {
        createButton.click();
    }

    public void enterFolderName(String groupName) {
        folderNameTextField.clear();
        folderNameTextField.sendKeys(groupName);
    }
}