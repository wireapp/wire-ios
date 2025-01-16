package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class CameraPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Take Photo")
    private WebElement takePhotoButton;

    @iOSXCUITFindBy(accessibility = "VideoCapture")
    private WebElement takeVideoButton;

    @iOSXCUITFindBy(accessibility = "Use Video")
    private WebElement useVideoButton;

    @iOSXCUITFindBy(accessibility = "Choose from Library")
    private WebElement chooseFromLibrary;

    public CameraPage(WebDriver driver) {
        super(driver);
    }

    public void tapTakePhoto() {
        takePhotoButton.click();
    }

    public void tapTakeVideo() {
        takeVideoButton.click();
    }

    public void tapUseVideo() {
        useVideoButton.click();
    }

    public boolean isTakePhotoButtonVisible() {
        return takePhotoButton.isDisplayed();
    }

    public boolean isChooseFromLibraryVisible() {
        return chooseFromLibrary.isDisplayed();
    }

    public void tapChooseFromLibrary() {
        chooseFromLibrary.click();
    }
}
