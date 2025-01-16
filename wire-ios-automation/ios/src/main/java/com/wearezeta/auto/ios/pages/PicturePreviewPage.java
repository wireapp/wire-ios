package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class PicturePreviewPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "sketchButton")
    private WebElement sketchButton;

    @iOSXCUITFindBy(accessibility = "OK")
    private WebElement oKButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'OK' AND name == 'OK' AND type == 'XCUIElementTypeButton'")
    private WebElement iPadOKButton;

    @iOSXCUITFindBy(accessibility = "Use Photo")
    private WebElement usePhotoButton;

    public PicturePreviewPage(WebDriver driver) {
        super(driver);
    }

    public void tapSketchButton(){
        sketchButton.click();
    }

    public void tapOkButton(){
        oKButton.click();
    }

    public void tapOkButtonOnIPad(){
        iPadOKButton.click();
    }

    public void tapPhotoButton(){
        usePhotoButton.click();
    }
}
