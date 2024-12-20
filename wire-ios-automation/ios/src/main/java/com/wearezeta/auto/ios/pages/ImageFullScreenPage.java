package com.wearezeta.auto.ios.pages;

import java.awt.image.BufferedImage;
import java.util.Optional;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class ImageFullScreenPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeScrollView[`name == 'fullScreenPage'`]/XCUIElementTypeImage")
    private WebElement fullScreenImage;

    public ImageFullScreenPage(WebDriver driver) {
        super(driver);
    }

    public boolean isImageFullScreenShown() {
        return waitUntilElementVisible(fullScreenImage);
    }

    public void tapFullScreenCloseButton() {
        waitUntilElementClickable(closeButton);
        closeButton.click();
    }

    public Optional<BufferedImage> getPreviewPictureScreenshot() {
        return Optional.ofNullable(getElementScreenshot(fullScreenImage)
                .orElseThrow(() -> new IllegalStateException("No visible images are detected in fullscreen mode")));
    }
}
