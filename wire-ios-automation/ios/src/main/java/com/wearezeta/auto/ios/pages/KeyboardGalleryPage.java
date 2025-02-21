package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class KeyboardGalleryPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "cameraRollButton")
    private WebElement openCameraRollButton;

    @iOSXCUITFindBy(accessibility = "fullscreenCameraButton")
    private WebElement fullscreenCameraButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeOther[$name == 'cameraRollButton'$]/" +
                            "**/XCUIElementTypeCollectionView/XCUIElementTypeCell[2]")
    private WebElement firstGalleryPicture;

    @iOSXCUITFindBy(xpath ="//XCUIElementTypeButton[@name=\"OK\"]")
    private WebElement okButton;

    public KeyboardGalleryPage(WebDriver driver) {
        super(driver);
    }

    public void selectFirstPicture() {
        firstGalleryPicture.click();
    }

    public void tapCameraRollButton(){
        openCameraRollButton.click();
    }

    public void tapFullScreenButton(){
        fullscreenCameraButton.click();
    }
    public void tapOkButton() {
        okButton.click();
    }

    public boolean isFirstItemGalleryVisible(){
        return firstGalleryPicture.isDisplayed();
    }

    public boolean isFirstItemGalleryInvisible(){
        return isElementInvisible(firstGalleryPicture);
    }
}
