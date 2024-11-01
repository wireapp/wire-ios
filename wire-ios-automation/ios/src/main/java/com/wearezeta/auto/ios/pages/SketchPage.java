package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class SketchPage extends IOSPage {
    @iOSXCUITFindBy(accessibility = "sendButton")
    private WebElement sendButton;

    @iOSXCUITFindBy(accessibility = "canvas")
    private WebElement canvasButton;

    public SketchPage(WebDriver driver) {
        super(driver);
    }

    public void sketchRandomLines() {
        swipe(canvasButton, SwipeDirection.UP);
        swipe(canvasButton, SwipeDirection.LEFT);
    }

    public void tapSendButton(){
        sendButton.click();
    }
}
