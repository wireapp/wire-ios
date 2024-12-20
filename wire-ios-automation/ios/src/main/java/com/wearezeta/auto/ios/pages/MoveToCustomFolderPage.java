package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.WebElement;

public class MoveToCustomFolderPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Move To")
    private WebElement moveToTitle;

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    @iOSXCUITFindBy(accessibility = "button.newfolder.create")
    private WebElement createNewButton;

    public MoveToCustomFolderPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return waitUntilElementVisible(moveToTitle);
    }

    public boolean isInvisible() {
        return waitUntilElementInvisible(moveToTitle);
    }

    public void tapCloseButton() {
        closeButton.click();
    }

    public void tapCreateNewButton() {
        createNewButton.click();
    }

    public void tapOnACustomFolder(String name) {
        getDriver().findElement(MobileBy.AccessibilityId(name)).click();
    }
}
