package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class VideoPlayerPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Play/Pause")
    private WebElement playPauseButton;

    @iOSXCUITFindBy(accessibility = "Done")
    private WebElement nameVideoDoneButton;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeApplication' AND name == 'Safari'")
    private WebElement predicateWebPlayer;

    public VideoPlayerPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVideoPlayerPageOpened() {
       return predicateWebPlayer.isDisplayed();
    }

    public boolean isPlayPauseButtonVisible() {
        return playPauseButton.isDisplayed();
    }

    public void tapDoneButton() {
        nameVideoDoneButton.click();
    }
}
