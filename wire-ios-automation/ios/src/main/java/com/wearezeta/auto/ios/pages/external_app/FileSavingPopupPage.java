package com.wearezeta.auto.ios.pages.external_app;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class FileSavingPopupPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeNavigationBar[`name == 'UIActivityContentView'`]/XCUIElementTypeOther/XCUIElementTypeOther")
    private WebElement fileLabel;

    @iOSXCUITFindBy(accessibility = "Close")
    private WebElement closeButton;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'Save to Files'")
    private WebElement saveToFilesButton;

    @iOSXCUITFindBy(accessibility = "On My iPhone")
    private WebElement onMyIPhoneChoice;

    @iOSXCUITFindBy(accessibility = "On My iPad")
    private WebElement onMyIPadChoice;

    @iOSXCUITFindBy(accessibility = "Save")
    private WebElement saveButton;

    public FileSavingPopupPage(WebDriver driver) {
        super(driver);
    }

    public String getFileLabel() {
        waitUntilElementVisible(fileLabel);
        return fileLabel.getAttribute("name");
    }

    public void tapSaveToFilesButton() {
        saveToFilesButton.click();
    }

    public void tapOnMyIPhone() {
        waitUntilElementVisible(onMyIPhoneChoice);
        onMyIPhoneChoice.click();
    }

    public void tapOnMyIPad() {
        waitUntilElementVisible(onMyIPadChoice);
        onMyIPadChoice.click();
    }

    public void tapSaveButton() {
        waitUntilElementClickable(saveButton);
        saveButton.click();
    }

    public void tapCloseButton() {
        closeButton.click();
    }
}
