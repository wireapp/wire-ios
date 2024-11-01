package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class GiphyPreviewPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "CANCEL")
    private WebElement cancelButton;

    @iOSXCUITFindBy(accessibility = "SEND")
    private WebElement sendButton;

    @iOSXCUITFindBy(accessibility = "giphyCollectionView")
    private WebElement previewGrid;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeCollectionView/*[1]")
    private WebElement firstGiphyInGrid;

    public GiphyPreviewPage(WebDriver driver) {
        super(driver);
    }

    public boolean isGridVisible() {
        return previewGrid.isDisplayed();
    }

    public void selectFirstItem() {
        waitUntilElementVisible(firstGiphyInGrid);
        firstGiphyInGrid.click();
    }

    public void tapSendButton() {
        sendButton.click();
    }

    public void tapCancelButton() {
        cancelButton.click();
    }

    public boolean isSendButtonVisible() {
        return sendButton.isDisplayed();
    }

    public boolean isCancelButtonVisible() {
        return cancelButton.isDisplayed();
    }
}