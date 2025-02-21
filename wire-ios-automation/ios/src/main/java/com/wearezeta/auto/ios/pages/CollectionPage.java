package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class CollectionPage extends IOSPage {

    @iOSXCUITFindBy(className = "XCUIElementTypeCollectionView")
    private WebElement collectionViewRoot;

    @iOSXCUITFindBy(accessibility = "back")
    private WebElement backButton;

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement closeButton;

    @iOSXCUITFindBy(accessibility = "fullScreenPage")
    private WebElement fullScreenPage;

    private static final Function<Integer, String> classChainStrPictureCollectionItemByIndex = idx ->
            String.format("**/XCUIElementTypeCell[" +
                    "$type == 'XCUIElementTypeImage' AND name == 'image'$][%s]", idx);

    public CollectionPage(WebDriver driver) {
        super(driver);
    }

    public void tapPictureItemByIndex(int index, boolean isLongTap) {
        final By locator = MobileBy.iOSClassChain(classChainStrPictureCollectionItemByIndex.apply(index));
        final WebElement dstElement = collectionViewRoot.findElement(locator);
        if (isLongTap) {
            longTapWithScript(dstElement, 50, 50);
        } else {
            tapAtTheCenterOfElement(dstElement);
        }
    }

    public boolean isFullScreenImagePreviewVisible() {
        return fullScreenPage.isDisplayed();
    }

    public void tapBackButton() {
        backButton.click();
    }

    public void tapCloseButton() {
        closeButton.click();
    }
}