package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.FilenameHelper;
import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;

import java.time.Duration;
import java.util.List;
import java.util.Map;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

import java.awt.image.BufferedImage;
import java.util.Optional;
import java.util.function.Function;

public class ConversationViewPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "ConversationBackButton")
    private WebElement conversationBackButton;

    @iOSXCUITFindBy(accessibility = "inputField")
    private WebElement conversationInput;

    @iOSXCUITFindBy(accessibility = "Call")
    private WebElement startCallButton;

    @iOSXCUITFindBy(accessibility = "videoCallBarButton")
    private WebElement videoCallButton;

    @iOSXCUITFindBy(accessibility = "Call anyway")
    private WebElement callAnywayButton;

    @iOSXCUITFindBy(accessibility = "Cancel")
    private WebElement cancelButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Upgrade to Enterprise\"`]")
    private WebElement upgradeAlert;

    @iOSXCUITFindBy(accessibility = "ImageCell")
    private WebElement imageCell;

    @iOSXCUITFindBy(accessibility = "VideoCell")
    private WebElement videoCell;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'ReplyCell'")
    private WebElement replyCell;

    @iOSXCUITFindBy(accessibility = "link-attachment")
    private WebElement youtubePreview;

    @iOSXCUITFindBy(accessibility = "mentionButton")
    private WebElement mentionButton;

    @iOSXCUITFindBy(accessibility = "sketchButton")
    private WebElement sketchButton;

    @iOSXCUITFindBy(accessibility = "photoButton")
    private WebElement addPictureButton;

    @iOSXCUITFindBy(accessibility = "gifButton")
    private WebElement gifButton;

    @iOSXCUITFindBy(accessibility = "audioButton")
    private WebElement audioMessageButton;

    @iOSXCUITFindBy(accessibility = "AudioActionButton")
    private WebElement audioMessageActionButton;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'AudioActionButton' AND value == 'Pause'")
    private WebElement audioMessagePauseButton;

    @iOSXCUITFindBy(accessibility = "showOtherRowButton")
    private WebElement ellipsisButton;

    @iOSXCUITFindBy(accessibility = "pingButton")
    private WebElement pingButton;

    @iOSXCUITFindBy(accessibility = "uploadFileButton")
    private WebElement fileTransferButton;

    @iOSXCUITFindBy(accessibility = "locationButton")
    private WebElement locationButton;

    @iOSXCUITFindBy(accessibility = "videoButton")
    private WebElement videoMessageButton;

    @iOSXCUITFindBy(accessibility = "sendButton")
    private WebElement sendButton;

    @iOSXCUITFindBy(accessibility = "VideoActionButton")
    private WebElement videoMessageActionButton;

    @iOSXCUITFindBy(accessibility = "audioRecorderSend")
    private WebElement audioRecorderSendButton;

    @iOSXCUITFindBy(accessibility = "ephemeralTimeSelectionButton")
    private WebElement hourglassButton;

    @iOSXCUITFindBy(accessibility = "collection")
    private WebElement collectionButton;

    @iOSXCUITFindBy(accessibility = "linkPreview")
    private WebElement linkPreview;

    @iOSXCUITFindBy(accessibility = "linkPreviewImage")
    private WebElement linkPreviewImage;

    @iOSXCUITFindBy(accessibility = "confirmButton")
    private WebElement confirmEdit;

    @iOSXCUITFindBy(accessibility = "cancelButton")
    private WebElement cancelEdit;

    @iOSXCUITFindBy(accessibility = "hasguests")
    private WebElement conversationHasGuestsIndicator;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeMap'")
    private WebElement sharedLocationContainer;

    @iOSXCUITFindBy(accessibility = "quote.type.image")
    private WebElement quotedImageInReply;

    @iOSXCUITFindBy(className = "XCUIElementTypePickerWheel")
    private WebElement pickerWheel;

    @iOSXCUITFindBy(accessibility = "likeButton")
    private WebElement likeButton;

    @iOSXCUITFindBy(accessibility = "MessageToolbox")
    private WebElement recentMessageToolbox;

    @iOSXCUITFindBy(accessibility = "FileTransferBottomLabel")
    private WebElement fileTransferBottomLabel;

    @iOSXCUITFindBy(accessibility = "FileTransferTopLabel")
    private WebElement fileTransferTopLabel;

    @iOSXCUITFindBy(accessibility = "DeliveryStatus")
    private WebElement messageDeliveryStatus;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'deep link' AND type == 'XCUIElementTypeLink'")
    private WebElement deepLinkMessage;

    @iOSXCUITFindBy(accessibility = "Image + MessageRestrictionBottomLabel")
    private WebElement placeholderPicture;

    @iOSXCUITFindBy(accessibility = "File + MessageRestrictionBottomLabel")
    private WebElement placeholderFile;

    @iOSXCUITFindBy(iOSNsPredicate = "label CONTAINS 'New Device' AND name CONTAINS 'New Device' AND value CONTAINS 'New Device'")
    private WebElement degradationAlert;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeNavigationBar'")
    private WebElement titleBar;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeNavigationBar/*[`name == 'Name'`]")
    private WebElement conversationName;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'users_list.label'")
    private WebElement userListLabel;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'Learn more'")
    private WebElement learnMoreDelayedMessage;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[$name == '80 MB file'$]")
    private WebElement optionFor80MBFile;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeButton[$name == 'CountryCodes.plist'$]")
    private WebElement optionForCountryCodesFile;

    private static final By classChainAllTextMessages = MobileBy.iOSClassChain("**/XCUIElementTypeCell[$name == 'Message'$]");

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeTextView[`name == 'Message' OR label == 'Message'`]")
    private WebElement lastTextMessage;

    private static final By nameFileTransferActionButton = MobileBy.AccessibilityId("FileTransferActionButton");

    private static final By nameFileActionsMenu = MobileBy.AccessibilityId("ActivityListView");

    private static final By nameImageCell = MobileBy.AccessibilityId("ImageCell");

    private static final By nameVideoCell = MobileBy.AccessibilityId("videoCell");

    private static final By nameFileTransferCell = MobileBy.AccessibilityId("FileTransferTopLabel");

    private static final By namePlaceholderImageCell = MobileBy.AccessibilityId("Image + MessageRestrictionBottomLabel");

    private static final String nameInputPlaceholderStandard = "Type a message";

    private static final By predicateStandardTextInputPlaceholder = MobileBy.iOSNsPredicateString(String.format("type == 'XCUIElementTypeTextView' AND name == 'inputField' AND value ENDSWITH '%s'", nameInputPlaceholderStandard));

    private static final Function<String, By> predicateInputFieldQuoteType = type -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeOther' AND name == 'replyView' AND label CONTAINS '%s'",
                    type));

    private static final Function<String, By> predicateStrQuotedMessageByValue = text -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeTextView' AND name =='quote.type.text' AND value CONTAINS '%s'", text));

    private static final By classChainConversationViewEntry = MobileBy.iOSClassChain("XCUIElementTypeCell");
    private static final String classChainStrAllEntries = "**/XCUIElementTypeTable/XCUIElementTypeCell";
    private static final By fbClassChainRecentEntry = MobileBy.iOSClassChain(String.format("%s[1]", classChainStrAllEntries));
    private static final By classConversationViewRoot = By.className("XCUIElementTypeTable");
    private static final By predicateMissedCallByYourself = MobileBy.iOSNsPredicateString("value == 'You called'");

    private static final Function<String, By> predicateReactionConversationViewByValue = reaction -> MobileBy.iOSNsPredicateString(String.format("type == 'XCUIElementTypeOther' AND name CONTAINS 'value: %s, count:'", reaction));

    private static final Function<String, By> classChainMessageToolboxByText = name -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCell[`name == 'MessageToolbox'`]/**/XCUIElementTypeAny[`value CONTAINS '%s' AND label CONTAINS '%s'`]", name, name));
    private static final Function<String, By> classChainMessageToolboxButtonByText = name -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCell[`name == 'MessageToolbox'`]/**/XCUIElementTypeButton[`label CONTAINS '%s'`]", name));

    /**
     * !!! The actual message order in DOM is reversed relatively to the messages order in the conversation view
     */
    private static final Function<String, String> messageAttributesByTextPartTemplate = text ->
            String.format("`name == 'Message' AND visible == 1 AND (value CONTAINS '%s' OR label CONTAINS '%s')`", text, text);

    private static final Function<String, By> classChainMessageByTextPart = text -> MobileBy.iOSClassChain(
            String.format("%s/**/*[%s]", classChainStrAllEntries, messageAttributesByTextPartTemplate.apply(text)));

    private static final Function<String, By> predicateSystemMessageByText = text -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeCell' AND label BEGINSWITH[c] '%s' OR type == 'XCUIElementTypeLink' AND label BEGINSWITH[c] '%s' OR type == 'XCUIElementTypeLink' AND value BEGINSWITH[c] '%s' OR type == 'XCUIElementTypeStaticText' AND label BEGINSWITH[c] '%s'", text, text, text, text));

    private static final Function<String, By> predicatePingMessageByText = text -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeLink' AND value ==[c] '%s'", text));

    private static final Function<Integer, By> xpathReplyCellsByCount = count -> By.xpath(
            String.format("//XCUIElementTypeTable[count(XCUIElementTypeCell[@name='ReplyCell'])=%s]", count));

    private static final String MISSED_CALL_PREFIX = "Missed call from";

    private static Function<String, String> classChainStrToolbarByPredicateExpr = predicateExpr ->
            String.format("**/XCUIElementTypeNavigationBar/*[`%s`]", predicateExpr);

    private static final By classChainTopBarShield = MobileBy.iOSClassChain(classChainStrToolbarByPredicateExpr.apply(
            "name == 'Name' AND label CONTAINS 'Verified'"));

    private static final By classChainTopBarLHIndicator = MobileBy.iOSClassChain(classChainStrToolbarByPredicateExpr.apply(
            "name == 'Name' AND label CONTAINS 'Legal hold'"));

    private static final Function<String, String> predicateTransferTopLabelByFileName = name ->
            String.format("type == 'XCUIElementTypeStaticText' AND name == 'FileTransferTopLabel' AND value == '%s'",
                    name.toUpperCase());

    private static final Function<String, String> predicateStrTransferBottomLabelByExpr = expr ->
            String.format("type == 'XCUIElementTypeStaticText' AND name == 'FileTransferBottomLabel' AND %s",
                    expr);

    private static final Function<String, String> predicateAudioActionButtonByState = value ->
            String.format("name == 'AudioActionButton' AND value == '%s'",
                    value);

    private static final Function<String, String> predicateStrMessageDeliveryStatusByText = text ->
            String.format("name == 'DeliveryStatus' AND value CONTAINS '%s'", text);

    private static final Function<String, String> predicateStrMessageDetailsByText = text ->
            String.format("name == 'Details' AND value CONTAINS '%s'", text);

    private static final Timedelta MAX_APPEARANCE_TIME = Timedelta.ofSeconds(20);

    public ConversationViewPage(WebDriver driver) {
        super(driver);
    }

    public boolean isInputFieldVisible() {
        return conversationInput.isDisplayed();
    }

    public boolean isInputFieldInvisible() {
        return isElementInvisible(conversationInput);
    }

    public boolean waitUntilTextMessageIsNotVisible(String msg) {
        final By locator = classChainMessageByTextPart.apply(msg);
        return isLocatorInvisible(locator);
    }

    public void returnToConversationsList() {
        waitUntilElementClickable(conversationBackButton);
        conversationBackButton.click();
    }

    public int getNumberOfMessageEntries() {
        final WebElement convoViewRoot = getElement(classConversationViewRoot);
        return selectVisibleElements(convoViewRoot, classChainConversationViewEntry).size();
    }

    public boolean waitForCursorInputVisible() {
        return isElementVisible(conversationInput, Timedelta.ofSeconds(10));
    }

    public boolean waitForCursorInputInvisible() {
        return isElementInvisible(conversationInput);
    }

    public void tapTextInput() {
        conversationInput.click();
    }

    public void longTapTextInput() throws InterruptedException {
        longTapWithActionsAPI(conversationInput);
    }

    public void clearTextInput() {
        // This is to make sure the input cursor has been put to the tail of the text
        this.tapByPercentOfElementSize(conversationInput, 95, 50);
        conversationInput.clear();
    }

    public String getLastTextMessage() {
        waitUntilElementVisible(lastTextMessage);
        return lastTextMessage.getText();
    }

    public boolean waitUntilMessageInConversation() {
        return waitUntilElementVisible(lastTextMessage);
    }

    public boolean isUpperToolbarContainNames(String expectedNames) {
        return titleBar.getAttribute("name").toUpperCase().equals(expectedNames.toUpperCase());
    }

    public void openConversationDetails() {
        waitUntilElementClickable(conversationName);
        conversationName.click();
    }

    public void typeMessage(String message, boolean shouldSend) {
        conversationInput.sendKeys(message);
        if (shouldSend) {
            tapSendMessageButton();
        }
    }

    public void typeMessage(String message) {
        typeMessage(message, false);
    }

    public boolean isShieldIconVisible() {
        return getDriver().findElement(classChainTopBarShield).isDisplayed();
    }

    public boolean isShieldIconInvisible() {
        return isLocatorInvisible(classChainTopBarShield);
    }

    public boolean areInputToolsVisible() {
        return isElementVisible(addPictureButton, Timedelta.ofSeconds(8)) || isElementVisible(ellipsisButton, Timedelta.ofSeconds(8));
    }

    public boolean areInputToolsInvisible() {
        return isElementInvisible(addPictureButton) && isElementInvisible(ellipsisButton);
    }

    public boolean isSystemMessageVisible(String expectedMsg) {
        final By locator = predicateSystemMessageByText.apply(expectedMsg);
        return getDriver().findElement(locator).isDisplayed();
    }

    public boolean isSystemMessageInvisible(String expectedMsg) {
        final By locator = predicateSystemMessageByText.apply(expectedMsg);
        return isLocatorInvisible(locator);
    }

    public boolean isPingMessageVisible(String pingMsg) {
        final By locator = predicatePingMessageByText.apply(pingMsg);
        return getDriver().findElement(locator).isDisplayed();
    }

    public boolean isPingMessageInvisible(String pingMsg) {
        final By locator = predicatePingMessageByText.apply(pingMsg);
        return isLocatorInvisible(locator);
    }

    public boolean isYouCalledMessageVisible() {
        return getDriver().findElement(predicateMissedCallByYourself).isDisplayed();
    }

    public Optional<BufferedImage> getRecentPictureScreenshot() {
        return getElementScreenshot(imageCell);
    }

    public List<String> getQRCodeFromPicture() {
        return waitUntilElementContainsQRCode(imageCell);
    }

    public void tapFileTransferOptionFor80MBFile() {
        optionFor80MBFile.click();
    }

    public void tapFileTransferOptionForCountryCodesFile() {
        optionForCountryCodesFile.click();
    }

    public boolean isFileTransferTopLabelVisible() {
        return fileTransferTopLabel.isDisplayed();
    }

    public boolean isFileTransferTopLabelInvisible() {
        return isElementInvisible(fileTransferTopLabel);
    }

    public boolean isFileTransferBottomLabelVisible() {
        return waitUntilElementVisible(fileTransferBottomLabel);
    }

    public void tapFileTransferActionButton() {
        tapElementWithRetryIfNextElementNotAppears(nameFileTransferActionButton, nameFileActionsMenu,
                Timedelta.ofSeconds(3), 5);
    }

    public void tapAddPictureButton() {
        addPictureButton.click();
    }

    public boolean isAddPictureButtonVisible() {
        return addPictureButton.isDisplayed();
    }

    public boolean isAddPictureButtonInvisible() {
        return isElementInvisible(addPictureButton);
    }

    public boolean isPingButtonVisible() {
        return locateCursorToolButton(pingButton).isDisplayed();
    }

    public boolean isPingButtonInvisible() {
        return isElementInvisible(pingButton);
    }

    public boolean isMentionButtonVisible() {
        return locateCursorToolButton(mentionButton).isDisplayed();
    }

    public boolean isMentionButtonInvisible() {
        return isElementInvisible(mentionButton);
    }

    public boolean isShareLocationButtonVisible() {
        return locateCursorToolButton(locationButton).isDisplayed();
    }

    public boolean isShareLocationButtonInvisible() {
        return isElementInvisible(locationButton);
    }

    public void tapMentionButton() {
        mentionButton.click();
    }

    public void tapPingButton() {
        pingButton.click();
    }

    public void tapSketchButton() {
        sketchButton.click();
    }

    public void tapShareLocationButton() {
        locationButton.click();
    }

    public void tapEllipsisButton() {
        ellipsisButton.click();
    }

    public void tapFileTransferButton() {
        fileTransferButton.click();
    }

    public void tapVideoMessageButton() {
        locateCursorToolButton(videoMessageButton).click();
    }

    public void tapAudioMessageButton() {
        locateCursorToolButton(audioMessageButton).click();
    }

    public void longTapAudioMessageButton() {
        if (waitUntilElementClickable(audioMessageButton)) {
            try {
                longTapWithActionsAPI(audioMessageButton);
            } catch (InterruptedException e) {
                throw new RuntimeException("Failed to long tap audio message button", e);
            }
        } else {
            throw new RuntimeException("Audio message button is not clickable");
        }

    }

    public void longTapAudioMessageButtonWithDuration(int seconds) {
        try {
            longTapWithActionsAPI(locateCursorToolButton(audioMessageButton), Duration.ofSeconds(seconds));
        } catch (InterruptedException e) {
            throw new RuntimeException("Could not long tap audio message button", e);
        }
    }

    public void tapGIFButton() {
        gifButton.click();
    }

    public boolean isAudioMessageButtonVisible() {
        return audioMessageButton.isDisplayed();
    }

    public boolean isAudioMessageButtonInvisible() {
        return isElementInvisible(audioMessageButton);
    }

    public boolean isFileTransferButtonVisible() {
        return locateCursorToolButton(fileTransferButton).isDisplayed();
    }

    public boolean isSketchButtonVisible() {
        return locateCursorToolButton(sketchButton).isDisplayed();
    }

    public boolean isSketchButtonInvisible() {
        return isElementInvisible(sketchButton);
    }

    public boolean isVideoMessageButtonVisible() {
        return locateCursorToolButton(videoMessageButton).isDisplayed();
    }

    public boolean isVideoMessageButtonInvisible() {
        return isElementInvisible(videoMessageButton);
    }

    public boolean isPhotoGalleryButtonVisible() {
        return addPictureButton.isDisplayed();
    }

    public boolean isPhotoGalleryButtonInvisible() {
        return isElementInvisible(addPictureButton);
    }

    public boolean isGiphyButtonVisible() {
        return locateCursorToolButton(gifButton).isDisplayed();
    }

    public boolean isGiphyButtonInvisible() {
        return isElementInvisible(gifButton);
    }

    public boolean isDegradationAlertVisible() {
        return degradationAlert.isEnabled();
    }

    public boolean isDegradationAlertInvisible() {
        return isElementInvisible(degradationAlert);
    }

    public boolean isFileTransferButtonInvisible() {
        return isElementInvisible(fileTransferButton);
    }

    public boolean waitUntilDownloadReadyPlaceholderVisible(String filename, String expectedSize, Timedelta timeout) {
        final By topLabelLocator = MobileBy.iOSNsPredicateString(
                predicateTransferTopLabelByFileName.apply(FilenameHelper.getBaseName(filename).get()));
        final By bottomLabelLocator = MobileBy.iOSNsPredicateString(predicateStrTransferBottomLabelByExpr.apply(
                String.join(" AND ",
                        String.format("value BEGINSWITH '%s'", expectedSize.toUpperCase()),
                        String.format("value CONTAINS '%s'", FilenameHelper.getExtension(filename).get().toUpperCase())
                )
        ));
        return isLocatorDisplayed(topLabelLocator, timeout) &&
                isLocatorDisplayed(bottomLabelLocator, timeout);
    }

    public boolean isPlaceholderStandardTextVisible() {
        return getDriver().findElement(predicateStandardTextInputPlaceholder).isDisplayed();
    }

    public boolean isPlaceholderStandardTextInvisible() {
        return isLocatorInvisible(predicateStandardTextInputPlaceholder);
    }

    public void longTapMessageByText(String message) {
        final WebElement el = getDriver().findElement(classChainMessageByTextPart.apply(message));
        getDriver().executeScript("mobile: touchAndHold", Map.ofEntries(
                Map.entry("elementId", el.getAttribute("UID")),
                Map.entry("duration", "2.0")
        ));
    }

    public void tapMessageByText(String text) {
        final WebElement el = getDriver().findElement(classChainMessageByTextPart.apply(text));
        tapAtTheLeftSideOfElement(el);
    }

    private WebElement locateCursorToolButton(WebElement toolButton) {
        if (isElementVisible(toolButton)) {
            return toolButton;
        } else {
            this.tapAtTheCenterOfElement(ellipsisButton);
            return toolButton;
        }
    }

    public void tapSendRecordControlButton() {
        audioRecorderSendButton.click();
    }

    public void tapAudioMessagePlayButton() {
        waitUntilElementClickable(audioMessageActionButton);
        audioMessageActionButton.click();
    }

    public void longTapPlayAudioMessageButton() {
        waitUntilElementClickable(audioMessageActionButton);
        longTapWithScript(audioMessageActionButton);
    }

    public boolean isPlaceholderAudioMessageButtonState(String buttonState) {
        final By locator = MobileBy.iOSNsPredicateString(predicateAudioActionButtonByState.apply(buttonState));
        return getDriver().findElement(locator).isDisplayed();
    }

    public boolean isAudioMessagePauseButtonVisible() {
        return waitUntilElementVisible(audioMessagePauseButton);
    }

    public boolean isLinkPreviewImageVisible() {
        return isElementVisible(linkPreviewImage, MAX_APPEARANCE_TIME);
    }

    public boolean isLinkPreviewImageInvisible() {
        return isElementInvisible(linkPreviewImage);
    }

    public void selectDeleteMenuItem(String name) {
        getElement(MobileBy.AccessibilityId(name)).click();
    }

    public void tapConfirmEditControlButton() {
        confirmEdit.click();
    }

    public void tapCancelEditControlButton() {
        cancelEdit.click();
    }

    public void tapImageInConversation() {
        imageCell.click();
    }

    public void longTapImageInConversation() {
        longTapWithScript(imageCell);
    }

    public void longTapFileTransferPlaceholder() {
        waitUntilElementVisible(fileTransferBottomLabel);
        longTapWithScript(fileTransferBottomLabel);
    }

    public void tapFileTransferPlaceholder() {
        fileTransferBottomLabel.click();
    }

    public void tapVideoMessage() {
        videoMessageActionButton.click();
    }

    public void longTapVideoMessage() {
        longTapWithScript(videoMessageActionButton);
    }

    public void tapLocationMap() {
        sharedLocationContainer.click();
    }

    public void longTapLinkPreview() {
        longTapWithScript(linkPreview);
    }

    public void singleTapYoutubePreview() {
        youtubePreview.click();
    }

    public boolean isVideoMessageVisible() {
        return videoMessageActionButton.isDisplayed();
    }

    public boolean isVideoMessageInvisible() {
        return isElementInvisible(videoMessageActionButton);
    }

    public boolean isLinkPreviewVisible() {
        return linkPreview.isDisplayed();
    }

    public boolean isLinkPreviewInvisible() {
        return isElementInvisible(linkPreview);
    }

    public boolean isAudioMessageVisible() {
        return waitUntilElementVisible(audioMessageActionButton);
    }

    public boolean isAudioMessageInvisible() {
        return waitUntilElementInvisible(audioMessageActionButton);
    }

    public boolean isLocationMapVisible() {
        return sharedLocationContainer.isDisplayed();
    }

    public boolean isLocationMapInvisible() {
        return isElementInvisible(sharedLocationContainer);
    }

    public BufferedImage getLikeIconState() {
        return getElementScreenshot(likeButton).orElseThrow(
                () -> new IllegalStateException("Cannot take a screenshot of Like/Unlike button")
        );
    }

    public void tapLikeIcon() {
        likeButton.click();
    }

    public boolean isLikeIconVisible() {
        return likeButton.isDisplayed() && recentMessageToolbox.isDisplayed();
    }

    public boolean isLikeIconInvisible() {
        return isElementInvisible(likeButton) || isElementInvisible(recentMessageToolbox);
    }

    public void tapAtRecentMessage(int pWidth, int pHeight) {
        this.tapByPercentOfElementSize(getElement(fbClassChainRecentEntry), pWidth, pHeight);
    }

    public void tapRecentMessageToolbox() {
        recentMessageToolbox.click();
    }

    public void tapAtDeepLinkMessage() {
        deepLinkMessage.click();
    }

    public boolean waitUntilAllTextMessageAreNotVisible() {
        return isLocatorInvisible(classChainAllTextMessages);
    }

    public int numberOfTextMessagesVisible(int expectedCount) {
        return waitUntilNumberOfElementsToBe(classChainAllTextMessages, expectedCount);
    }

    public int numberOfSpecificTextMessagesVisible(String s, int expectedCount) {
        final By locator = classChainMessageByTextPart.apply(s);
        return waitUntilNumberOfElementsToBe(locator, expectedCount);
    }

    public boolean areNoImagesVisible() {
        return waitUntilElementInvisible(imageCell);
    }

    public int numberOfImagesVisible(int expectedCount) {
        return waitUntilNumberOfElementsToBe(nameImageCell, expectedCount);
    }

    public boolean areNoVideoFilesVisible() {
        return waitUntilElementInvisible(videoCell);
    }

    public int numberOfVideoFiles(int expectedCount) {
        return waitUntilNumberOfElementsToBe(nameVideoCell, expectedCount);
    }

    public int areXFilesVisible(int expectedCount) {
        return waitUntilNumberOfElementsToBe(nameFileTransferCell, expectedCount);
    }

    public String getPlaceholderImageText() {
        return placeholderPicture.getText();
    }

    public boolean areNoPlaceholderImagesVisible() {
        return isElementInvisible(placeholderPicture);
    }

    public boolean isPlaceholderFileVisible() {
        return placeholderFile.isDisplayed();
    }

    public boolean isPlaceholderFileInvisible() {
        return isElementInvisible(placeholderFile);
    }

    public void longTapPlaceholderFile() {
        longTapWithScript(placeholderFile);
    }

    public int numberOfPlaceholderImages(int expectedCount) {
        return waitUntilNumberOfElementsToBe(namePlaceholderImageCell, expectedCount);
    }

    public void tapStartCallButton() {
        startCallButton.click();
    }

    public void startCall() {
        videoCallButton.click();
    }

    public void tapCancelButton() {
        tapAtTheCenterOfElement(cancelButton);
    }

    public void tapCallAnywayButton() {
        waitUntilElementVisible(callAnywayButton);
        tapAtTheCenterOfElement(callAnywayButton);
    }

    public void tapSendMessageButton() {
        sendButton.click();
    }

    public void sendMessage(String text) {
        typeMessage(text);
        tapSendMessageButton();
    }

    public void tapHourglassButton() {
        hourglassButton.click();
    }

    public void tapCollectionButton() {
        this.tapElementWithRetryIfStillDisplayed(collectionButton);
    }

    public boolean isMessageDeliveryStatusTextVisible(String expectedText) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrMessageDeliveryStatusByText.apply(expectedText));
        return getDriver().findElement(locator).isDisplayed();
    }

    public boolean isMessageToolboxDetailsTextVisible(String expectedText) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrMessageDetailsByText.apply(expectedText));
        return getDriver().findElement(locator).isDisplayed();
    }

    public boolean isMessageToolboxDetailsTextInvisible(String expectedText) {
        final By locator = MobileBy.iOSNsPredicateString(predicateStrMessageDetailsByText.apply(expectedText));
        return isLocatorInvisible(locator);
    }

    public boolean isMessageToolboxTextVisible(String expectedText) {
        By locator = classChainMessageToolboxByText.apply(expectedText);
        return waitUntilLocatorVisible(locator);
    }

    public boolean isMessageToolboxButtonVisible(String expectedText) {
        By locator = classChainMessageToolboxButtonByText.apply(expectedText);
        return getDriver().findElement(locator).isDisplayed();
    }

    public boolean isMessageToolboxButtonInvisible(String expectedText) {
        By locator = classChainMessageToolboxButtonByText.apply(expectedText);
        return isLocatorInvisible(locator, MAX_APPEARANCE_TIME);
    }

    public boolean isMessageToolboxTextInvisible(String expectedText) {
        final By locator = classChainMessageToolboxByText.apply(expectedText);
        return isLocatorInvisible(locator);
    }

    public boolean isMessageDeliveryStatusVisible() {
        return waitUntilElementVisible(messageDeliveryStatus, MAX_APPEARANCE_TIME.asDuration());
    }

    public boolean isMessageDeliveryStatusInvisible() {
        return isElementInvisible(messageDeliveryStatus);
    }

    public void setMessageExpirationTimer(String value) {
        pickerWheel.sendKeys(value);
    }

    private static final int MAX_SCROLLS = 3;

    public void scrollToTheTop() {
        for (int i = 0; i < MAX_SCROLLS; i++) {
            swipe(getElement(classConversationViewRoot), SwipeDirection.DOWN);
        }
    }

    public void scrollToTheBottom() {
        for (int i = 0; i < MAX_SCROLLS; i++) {
            swipe(getElement(classConversationViewRoot), SwipeDirection.UP);
        }
    }

    public boolean isConversationHasGuestsVisible() {
        return conversationHasGuestsIndicator.isDisplayed();
    }

    public boolean isConversationHasGuestsInvisible() {
        return isElementInvisible(conversationHasGuestsIndicator);
    }

    public boolean isReplyVisible() {
        return replyCell.isDisplayed();
    }

    public boolean isReplyInvisible() {
        return isElementInvisible(replyCell);
    }

    public boolean isInputFieldQuoteOfTypeVisible(String type) {
        return isLocatorExist(predicateInputFieldQuoteType.apply(type));
    }

    public boolean isQuotedImageVisible() {
        return quotedImageInReply.isDisplayed();
    }

    public boolean isQuotedMessageVisible(String text) {
        return getDriver().findElement(predicateStrQuotedMessageByValue.apply(text)).isDisplayed();
    }

    public boolean isNumberOfReplyCellsVisible(int numberOfCells) {
        return getDriver().findElement(xpathReplyCellsByCount.apply(numberOfCells)).isDisplayed();
    }

    public boolean isLegalHoldIndicatorVisible() {
        return isLocatorDisplayed(classChainTopBarLHIndicator, Timedelta.ofSeconds(10));
    }

    public boolean isLegalHoldIndicatorInvisible() {
        return isLocatorInvisible(classChainTopBarLHIndicator);
    }

    public boolean isUserWillGetYourMessageLaterVisible(String name) {
        return userListLabel.getText().equals(String.format("%s will get your message later. Learn more", name));
    }

    public void iTapOnLearnMoreLinkOnDelayedMessage() {
        learnMoreDelayedMessage.click();
    }

    public boolean isReactionVisible(String reaction) {
        return getDriver().findElement(predicateReactionConversationViewByValue.apply(reaction)).isDisplayed();
    }

    public boolean isReactionInvisible(String reaction) {
        return isLocatorInvisible(predicateReactionConversationViewByValue.apply(reaction));
    }

    public boolean enterpriseUpgradeAlertPresent() {
        try {
            return upgradeAlert.isDisplayed();
        } catch(Exception e) {
            return false;
        }
    }
}
