package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class CameraRollPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeScrollView/**/XCUIElementTypeImage[`label BEGINSWITH 'Photo'`][-1]")
    private WebElement cameraRollPicture;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeScrollView/**/XCUIElementTypeImage[`label BEGINSWITH 'Photo'`]")
    private WebElement firstCameraRollPicture;

    public CameraRollPage(WebDriver driver) {
        super(driver);
    }

    public void selectPicture() {
        cameraRollPicture.click();
    }

    public void selectFirstPicture() {
        firstCameraRollPicture.click();
    }
}
