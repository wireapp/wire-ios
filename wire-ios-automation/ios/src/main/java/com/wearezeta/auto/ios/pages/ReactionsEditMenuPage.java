package com.wearezeta.auto.ios.pages;

import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class ReactionsEditMenuPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Reactions")
    private WebElement emojiPicker;

    @iOSXCUITFindBy(accessibility = "Forward")
    private WebElement forwardButton;

    @iOSXCUITFindBy(accessibility = "Copy")
    private WebElement copyItem;

    @iOSXCUITFindBy(accessibility = "Delete")
    private WebElement deleteItem;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND name == 'Details'")
    private WebElement detailsItem;

    @iOSXCUITFindBy(accessibility = "Download")
    private WebElement downloadItem;

    @iOSXCUITFindBy(accessibility = "Edit")
    private WebElement editItem;

    @iOSXCUITFindBy(accessibility = "Like")
    private WebElement likeItem;

    @iOSXCUITFindBy(accessibility = "Unlike")
    private WebElement unlikeItem;

    @iOSXCUITFindBy(accessibility = "Paste")
    private WebElement pasteItem;

    @iOSXCUITFindBy(accessibility = "Reply")
    private WebElement replyItem;

    @iOSXCUITFindBy(accessibility = "Reveal")
    private WebElement revealItem;

    @iOSXCUITFindBy(accessibility = "Save")
    private WebElement saveItem;

    @iOSXCUITFindBy(accessibility = "Select All")
    private WebElement selectAll;

    @iOSXCUITFindBy(accessibility = "Share")
    private WebElement shareItem;

    @iOSXCUITFindBy(accessibility = "Cancel")
    private WebElement cancelItem;

    private static final Function<String, By> predicateReactionByValue = reaction -> MobileBy.iOSNsPredicateString(String.format("type == 'XCUIElementTypeButton' AND name == '%s'", reaction));

    public ReactionsEditMenuPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return waitUntilElementVisible(emojiPicker);
    }

    public boolean isInvisible() {
        return waitUntilElementInvisible(emojiPicker);
    }

    public void iTapQuickReaction(String reaction) {
        getDriver().findElement(predicateReactionByValue.apply(reaction)).click();
    }

    public boolean isForwardButtonInvisible() {
        return waitUntilElementInvisible(forwardButton);
    }

    public void tapCopy() {
        copyItem.click();
    }

    public boolean isCopyVisible() {
        return waitUntilElementVisible(copyItem);
    }

    public boolean isCopyInvisible() {
        return waitUntilElementInvisible(copyItem);
    }

    public void tapDelete() {
        deleteItem.click();
    }

    public boolean isDeleteVisible() {
        return waitUntilElementVisible(deleteItem);
    }

    public void tapDetails() {
        detailsItem.click();
    }

    public void tapDownload() {
        downloadItem.click();
    }

    public boolean isDownloadInvisible() {
        return waitUntilElementInvisible(downloadItem);
    }

    public void tapEdit() {
        editItem.click();
    }

    public void tapLike() {
        likeItem.click();
    }

    public void tapPaste() {
        pasteItem.click();
    }

    public boolean isPasteInvisible() {
        return waitUntilElementInvisible(pasteItem);
    }

    public void tapReply() {
        replyItem.click();
    }

    public boolean isReplyVisible() {
        return waitUntilElementVisible(replyItem);
    }

    public void tapSave() {
        saveItem.click();
    }

    public boolean isSaveVisible() {
        return waitUntilElementVisible(saveItem);
    }

    public boolean isSaveInvisible() {
        return waitUntilElementInvisible(saveItem);
    }

    public void tapSelectAll() {
        selectAll.click();
    }

    public void tapShare() {
        shareItem.click();
    }

    public boolean isShareVisible() {
        return waitUntilElementVisible(shareItem);
    }

    public boolean isShareInvisible() {
        return waitUntilElementInvisible(shareItem);
    }

    public void tapCancel() {
        cancelItem.click();
    }
}
