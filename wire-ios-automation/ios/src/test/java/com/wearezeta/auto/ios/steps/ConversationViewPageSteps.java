package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.ImageUtil;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager.FindBy;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ConversationViewPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static com.wearezeta.auto.ios.common.Pinger.log;
import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;

import java.util.Optional;
import java.awt.image.BufferedImage;

import static com.wearezeta.auto.common.CommonSteps.DEFAULT_AUTOMATION_MESSAGE;

public class ConversationViewPageSteps {

    IOSTestContext context;

    public ConversationViewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ConversationViewPage getConversationViewPage() {
        return context.getPagesCollection().getPage(ConversationViewPage.class);
    }

    @When("^I see conversation view page$")
    public void WhenISeePage() {
        ISeeTextInput(null);
    }

    @When("^I tap on text input$")
    public void iTapOnTextInput() {
        getConversationViewPage().tapTextInput();
    }

    @When("^I long tap on text input$")
    public void iLongTapOnTextInput() {
        try {
            getConversationViewPage().longTapTextInput();
        } catch (InterruptedException e) {
            log.severe(String.format("Caught Interrupted exception: %s", e.getMessage()));
        }
    }

    @When("^I scroll to the (top|bottom) of the conversation$")
    public void ScrollToThe(String where) {
        if (where.equals("top")) {
            getConversationViewPage().scrollToTheTop();
        } else {
            getConversationViewPage().scrollToTheBottom();
        }
    }

    @When("^I (do not )?see text input in conversation view$")
    public void ISeeTextInput(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Cursor input is not visible", getConversationViewPage().waitForCursorInputVisible());
        } else {
            assertThat("Cursor input is visible, but should be hidden",
                    getConversationViewPage().waitForCursorInputInvisible());
        }
    }

    @When("^I type the (default|.*) message$")
    public void WhenITypeTheMessage(String msg) {
        if (msg.equals("default")) {
            getConversationViewPage().typeMessage(DEFAULT_AUTOMATION_MESSAGE);
        } else {
            msg = context.getUsersManager()
                    .replaceAliasesOccurrences(msg, FindBy.NAME_ALIAS);
            msg = context.getUsersManager()
                    .replaceAliasesOccurrences(msg, FindBy.UNIQUE_USERNAME_ALIAS);
            getConversationViewPage().typeMessage(msg.replaceAll("^\"|\"$", ""));
        }
    }

    @When("^I type first (\\d+) letters? of name \"(.*)\" in conversation input$")
    public void ITypeXLettersIntoSearchInput(int count, String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, FindBy.NAME_ALIAS);
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, FindBy.UNIQUE_USERNAME_ALIAS);

        if (name.length() > count) {
            getConversationViewPage().typeMessage(name.substring(0, count));
        } else {
            throw new IllegalArgumentException(String.format("Name is only %s chars length. Put in step a less value",
                    name.length()));
        }
    }

    /**
     * Verify whether the particular system message is visible in the conversation view
     *
     * @param expectedMsg  the expected system message. may contyain user name aliases
     * @param shouldNotSee equals to null if the message should be visible
     */
    @Then("^I (do not )?see \"(.*)\" system message in the conversation view$")
    public void ISeeSystemMessage(String shouldNotSee, String expectedMsg) {
        expectedMsg = context.getUsersManager()
                .replaceAliasesOccurrences(expectedMsg, FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("The expected system message '%s' is not visible in the conversation",
                    expectedMsg), getConversationViewPage().isSystemMessageVisible(expectedMsg));
        } else {
            assertThat(String.format(
                    "The expected system message '%s' should not be visible in the conversation",
                    expectedMsg), getConversationViewPage().isSystemMessageInvisible(expectedMsg));
        }
    }

    /**
     * Verify whether the ping message is visible in the conversation view
     *
     * @param expectedMsg  ping message containing user name or you
     * @param shouldNotSee equals to null if the message should be visible
     */
    @Then("^I (do not )?see \"(.*)\" ping message in the conversation view$")
    public void ISeePingMessage(String shouldNotSee, String expectedMsg) {
        expectedMsg = context.getUsersManager()
                .replaceAliasesOccurrences(expectedMsg, FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("The expected ping message '%s' is not visible in the conversation",
                    expectedMsg), getConversationViewPage().isPingMessageVisible(expectedMsg));
        } else {
            assertThat(String.format(
                    "The expected ping message '%s' should not be visible in the conversation",
                    expectedMsg), getConversationViewPage().isPingMessageInvisible(expectedMsg));
        }
    }

    /**
     * Type a default message or the given message in conversation view and send it
     *
     * @param msg the message that is going to be typed
     */
    @When("^I type the (default|\".*\") message and send it$")
    public void ITypeTheMessageAndSendIt(String msg) {
        if (msg.equals("default")) {
            getConversationViewPage().typeMessage(DEFAULT_AUTOMATION_MESSAGE, true);
        } else {
            msg = context.getUsersManager()
                    .replaceAliasesOccurrences(msg, FindBy.NAME_ALIAS);
            getConversationViewPage().typeMessage(msg.replaceAll("^\"|\"$", ""), true);
        }
    }

    @When("^I tap Send Message button in conversation view$")
    public void ITapSendMessageConvoButton() {
        getConversationViewPage().tapSendMessageButton();
    }

    @When("^I tap Hourglass button in conversation view$")
    public void ITapHourglassConvoButton() {
        getConversationViewPage().tapHourglassButton();
    }

    @When("^I tap Collection button in conversation view$")
    public void ITapCollectionConvoButton() {
        getConversationViewPage().tapCollectionButton();
    }

    /**
     * Click open conversation details button in 1:1 dialog
     */
    @When("^I open (?:group |\\s?)conversation details$")
    public void IOpenConversationDetails() {
        getConversationViewPage().openConversationDetails();
    }

    /**
     * Wait until text messages are visible in the conversation
     *
     * @param expectedCount the expected count of messages. Should be equal or greater than zero
     * @param isDefault     equals to null if presence of any messages are supposed to be verified
     */
    @Then("^I see (\\d+) (default )?messages? in the conversation view$")
    public void ThenISeeMessageInTheDialog(int expectedCount, String isDefault) {
        final Optional<String> expectedMsg = (isDefault == null) ?
                Optional.empty() : Optional.of(DEFAULT_AUTOMATION_MESSAGE);
        if (expectedCount == 0) {
            if (expectedMsg.isPresent()) {
                assertThat(
                        String.format("There are some '%s' messages in the conversation, but zero is expected",
                                expectedMsg.get()),
                        getConversationViewPage().waitUntilTextMessageIsNotVisible(expectedMsg.get()));
            } else {
                assertThat("There are some messages in the conversation, but zero is expected",
                        getConversationViewPage().waitUntilAllTextMessageAreNotVisible());
            }
        } else if (expectedCount >= 1) {
            if (expectedMsg.isPresent()) {
                assertThat("Unexpected number of specific messages",
                        getConversationViewPage().numberOfSpecificTextMessagesVisible(
                                expectedMsg.get(),
                                expectedCount),
                        equalTo(expectedCount));
            } else {
                assertThat("Unexpected number of messages",
                        getConversationViewPage().numberOfTextMessagesVisible(expectedCount),
                        equalTo(expectedCount));
            }
        }
    }

    @Then("^I see at least one message in the conversation view")
    public void iSeeAtLeastMessage() {
        assertThat("There seems to be no message in the current view",
                getConversationViewPage().waitUntilMessageInConversation());
    }

    @Then("^I see last message in the conversation view is expected message (.*)")
    public void iSeeLastMessageIs(String msg) {
        msg = context.getUsersManager().replaceAliasesOccurrences(msg, FindBy.EMAIL_ALIAS);
        msg = context.getUsersManager().replaceAliasesOccurrences(msg, FindBy.NAME_ALIAS);
        assertThat("The last message in the conversation is different from the expected",
                getConversationViewPage().getLastTextMessage(), equalTo(msg));
    }

    @Then("^I see last message in the conversation view contains expected message (.*)")
    public void iSeeLastMessageContains(String msg) {
        msg = context.getUsersManager().replaceAliasesOccurrences(msg, FindBy.EMAIL_ALIAS);
        msg = context.getUsersManager().replaceAliasesOccurrences(msg, FindBy.NAME_ALIAS);
        assertThat("The last message in the conversation does not contain the expected one",
                getConversationViewPage().getLastTextMessage(), containsString(msg));
    }

    @When("^I tap Add Picture button from input tools$")
    public void ITapAddPictureButtonByNameFromInputTools() {
        getConversationViewPage().tapAddPictureButton();
    }

    @When("^I tap Mention button from input tools$")
    public void ITapMentionButtonByNameFromInputTools() {
        getConversationViewPage().tapMentionButton();
    }

    @When("^I tap Sketch button from input tools$")
    public void ITapSketchButtonByNameFromInputTools() {
        getConversationViewPage().tapSketchButton();
    }

    @When("^I tap ellipsis button from input tools$")
    public void iTapEllipsisButtonByNameFromInputTools() {
        getConversationViewPage().tapEllipsisButton();
    }

    @When("^I tap Ping button from input tools$")
    public void ITapPingButtonByNameFromInputTools() {
        getConversationViewPage().tapPingButton();
    }

    @When("^I tap File Transfer button from input tools$")
    public void ITapFileTransferButtonByNameFromInputTools() {
        getConversationViewPage().tapFileTransferButton();
    }

    @When("^I tap Share Location button from input tools$")
    public void ITapShareLocationButtonByNameFromInputTools() {
        getConversationViewPage().tapShareLocationButton();
    }

    @When("^I tap Video Message button from input tools$")
    public void ITapVideoMessageButtonByNameFromInputTools() {
        getConversationViewPage().tapVideoMessageButton();
    }

    @When("^I tap Audio Message button from input tools$")
    public void ITapAudioMessageButtonByNameFromInputTools() {
        getConversationViewPage().tapAudioMessageButton();
    }

    @When("^I long tap Audio Message button from input tools$")
    public void ILongTapAudioMessageButtonByNameFromInputTools() {
        getConversationViewPage().longTapAudioMessageButton();
    }

    @When("^I long tap Audio Message button for (\\d+) seconds from input tools$")
    public void ILongTapForSecondsAudioMessageButtonByNameFromInputTools(int durationSeconds) {
        getConversationViewPage().longTapAudioMessageButtonWithDuration(durationSeconds);
    }

    @When("^I tap GIF button from input tools$")
    public void ITapGIFButtonByNameFromInputTools() {
        getConversationViewPage().tapGIFButton();
    }

    @When("^I (do not )?see Audio Message button in input tools palette$")
    public void iSeeAudioMessageButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Audio Message button in input tools palette is not visible",
                    getConversationViewPage().isAudioMessageButtonVisible());
        } else {
            assertThat("Audio Message button in input tools palette is visible",
                    getConversationViewPage().isAudioMessageButtonInvisible());
        }
    }

    @When("^I (do not )?see File Transfer button in input tools palette$")
    public void iSeeFileTransferButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("File Transfer button in input tools palette is not visible",
                    getConversationViewPage().isFileTransferButtonVisible());
        } else {
            assertThat("File Transfer button in input tools palette is visible",
                    getConversationViewPage().isFileTransferButtonInvisible());
        }
    }

    @When("^I (do not )?see Video Message button in input tools palette$")
    public void iSeeVideoMessageButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Video Message button in input tools palette is not visible",
                    getConversationViewPage().isVideoMessageButtonVisible());
        } else {
            assertThat("Video Message button in input tools palette is visible",
                    getConversationViewPage().isVideoMessageButtonInvisible());
        }
    }

    @When("^I (do not )?see phone gallery button in a draw sketch view$")
    public void iSeeGalleryon(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Photo gallery button in a draw sketch view is not visible",
                    getConversationViewPage().isPhotoGalleryButtonVisible());
        } else {
            assertThat("Photo gallery button in a draw sketch view is visible",
                    getConversationViewPage().isPhotoGalleryButtonInvisible());
        }
    }

    @When("^I (do not )?see Sketch button in input tools palette$")
    public void iSeeSketchButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Sketch button in input tools palette is not visible",
                    getConversationViewPage().isSketchButtonVisible());
        } else {
            assertThat("Sketch button in input tools palette is visible",
                    getConversationViewPage().isSketchButtonInvisible());
        }
    }

    @When("^I (do not )?see Giphy button in input tools palette$")
    public void iSeeGiphyButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Giphy button in input tools palette is not visible",
                    getConversationViewPage().isGiphyButtonVisible());
        } else {
            assertThat("Giphy button in input tools palette is visible",
                    getConversationViewPage().isGiphyButtonInvisible());
        }
    }

    @When("^I (do not )?see degradation alert contains text New Device$")
    public void iSeeDegradationAlert(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Degradation alert in a call is not visible",
                    getConversationViewPage().isDegradationAlertVisible());
        } else {
            assertThat("Degradation alert in a call is visible",
                    getConversationViewPage().isDegradationAlertInvisible());
        }
    }

    @When("^I (do not )?see Add Picture button in input tools palette$")
    public void iSeeAddPictureButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Add Picture button in input tools palette is not visible",
                    getConversationViewPage().isAddPictureButtonVisible());
        } else {
            assertThat("Add Picture button in input tools palette is visible",
                    getConversationViewPage().isAddPictureButtonInvisible());
        }
    }

    @When("^I (do not )?see Ping button in input tools palette$")
    public void iSeePingButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Ping button in input tools palette is not visible",
                    getConversationViewPage().isPingButtonVisible());
        } else {
            assertThat("Ping button in input tools palette is visible",
                    getConversationViewPage().isPingButtonInvisible());
        }
    }

    @When("^I (do not )?see Mention button in input tools palette$")
    public void iSeeMentionButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Mention button in input tools palette is not visible",
                    getConversationViewPage().isMentionButtonVisible());
        } else {
            assertThat("Mention button in input tools palette is visible",
                    getConversationViewPage().isMentionButtonInvisible());
        }
    }

    @When("^I (do not )?see Share Location button in input tools palette$")
    public void iSeeShareLocationButton(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Share Location button in input tools palette is not visible",
                    getConversationViewPage().isShareLocationButtonVisible());
        } else {
            assertThat("Share Location button in input tools palette is visible",
                    getConversationViewPage().isShareLocationButtonInvisible());
        }
    }

    @When("^I start a call$")
    public void iStartCall() {
        getConversationViewPage().startCall();
    }

    @When(("I tap call button on start call alert"))
    public void ITapCallButton() {
        getConversationViewPage().tapStartCallButton();
    }

    @When("^I tap Video Call button$")
    public void ITapVideoCallButton() {
        getConversationViewPage().startCall();
    }

    @When("^I tap call anyway on degradation alert$")
    public void ITapCallAnywayButton() {
        getConversationViewPage().tapCallAnywayButton();
    }

    @When("^I tap cancel button on degradation alert$")
    public void ITapCancelButton() {
        getConversationViewPage().tapCancelButton();
    }

    @Then("^I see (\\d+) photos? in the conversation view$")
    public void ISeeNewPhotoInTheDialog(int expectedCount) {
        if (expectedCount == 0) {
            assertThat("No images are expected to be visible in the conversations",
                    getConversationViewPage().areNoImagesVisible());
        } else {
            assertThat("Unexpected number of images",
                    getConversationViewPage().numberOfImagesVisible(expectedCount),
                    equalTo(expectedCount));
        }
    }

    @Then("^I see (\\d+) video? files in the conversation view$")
    public void ISeeNewVideoInTheDialog(int expectedCount) {
        if (expectedCount == 0) {
            assertThat("No Video files are expected to be visible in the conversations",
                    getConversationViewPage().areNoVideoFilesVisible());
        } else {
            assertThat("Unexpected number of video files",
                    getConversationViewPage().numberOfVideoFiles(expectedCount),
                    equalTo(expectedCount));
        }
    }

    @Then("^I see (\\d+) file? transfer placeholder in the conversation view$")
    public void ISeeNewFileInTheDialog(int expectedCount) {
        if (expectedCount == 0) {
            assertThat("File transfer placeholder is visible in the conversations",
                    getConversationViewPage().isFileTransferTopLabelInvisible());
        } else {
            assertThat("Unexpected number of file placeholders",
                    getConversationViewPage().areXFilesVisible(expectedCount),
                    equalTo(expectedCount));
        }
    }

    @Then("^I see (\\d+) placeholder photos? in the conversation view$")
    public void iSeePlaceholderPhoto(int expectedCount) {
        if (expectedCount == 0) {
            assertThat("No placeholder images are expected to be visible in the conversations",
                    getConversationViewPage().areNoPlaceholderImagesVisible());
        } else {
            assertThat("Unexpected number of placeholder images",
                    getConversationViewPage().numberOfPlaceholderImages(expectedCount),
                    equalTo(expectedCount));
        }
    }

    @Then("^I (do not )?see a placeholder file in the conversation view$")
    public void iSeePlaceholderFile(String doNot) {
        if (doNot == null) {
            assertThat(
                    "Placeholder File is expected to be visible in the conversations",
                    getConversationViewPage().isPlaceholderFileVisible());
        } else {
            assertThat(
                    "Placeholder File is expected to be invisible in the conversations",
                    getConversationViewPage().isPlaceholderFileInvisible());
        }
    }

    @When("^I long tap on restricted file transfer placeholder in conversation view$")
    public void iLongTapPlaceholderFile() {
        getConversationViewPage().longTapPlaceholderFile();
    }

    @Then("^I see text (.*) displayed on placeholder photo$")
    public void iSeeTextOnPlaceholderPhoto(String expectedText) {
        assertThat(
                String.format("Text %s is not displayed on the placeholder image", expectedText),
                getConversationViewPage().getPlaceholderImageText(), equalTo(expectedText));
    }

    @When("^I navigate back to conversations list")
    public void INavigateToConversationsList() {
        getConversationViewPage().returnToConversationsList();
    }

    @Then("^I (do not )?see TYPE A MESSAGE input placeholder text$")
    public void ISeeStandardInputPlaceholderText(String shouldNotBeVisible) {
        boolean result;
        if (shouldNotBeVisible == null) {
            result = getConversationViewPage().isPlaceholderStandardTextVisible();
        } else {
            result = getConversationViewPage().isPlaceholderStandardTextInvisible();
        }
        assertThat(
                String.format("TYPE A MESSAGE placeholder text should be %s", (shouldNotBeVisible == null) ? "visible" : "not visible"),
                result
        );
    }

    @When("^I see the conversation with (.*) is opened$")
    public void ISeeConversationWith(String participantNameAlias) {
        participantNameAlias = context.getUsersManager()
                .replaceAliasesOccurrences(participantNameAlias, ClientUsersManager.FindBy.NAME_ALIAS);

        assertThat(
                String.format("User '%s' are not displayed on Upper Toolbar", participantNameAlias),
                getConversationViewPage().isUpperToolbarContainNames(participantNameAlias)
        );
    }

    /**
     * Verify that all buttons in toolbar are visible or not
     *
     * @param shouldNotBeVisible equals to null if the toolbar should be visible
     */
    @When("^I (do not )?see conversation tools buttons$")
    public void ISeeOnlyPeopleButtonRestNotShown(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("Some of input tools buttons are not visible",
                    getConversationViewPage().areInputToolsVisible());
        } else {
            assertThat("Some of input tools buttons are still visible",
                    getConversationViewPage().areInputToolsInvisible());
        }
    }

    /**
     * Verifies amount of messages in conversation
     *
     * @param expectedCount expected number of messages
     */
    @When("^I see (\\d+) conversation (?:entries|entry)$")
    public void ISeeXConvoEntries(int expectedCount) {
        assertThat("The expected count of conversation entries is not equal to the actual count",
                getConversationViewPage().getNumberOfMessageEntries(), equalTo(expectedCount));
    }

    /**
     * Select the corresponding item from the modal menu, which appears after Delete badge is tapped
     *
     * @param name one of possible item names
     */
    @When("^I select (Delete for Me|Delete for Everyone|Cancel) item from Delete menu$")
    public void ISelectDeleteMenuItem(String name) {
        getConversationViewPage().selectDeleteMenuItem(name);
    }

    /**
     * Clear conversation text input
     */
    @When("^I clear conversation text input$")
    public void IClearConversationTextInput() {
        getConversationViewPage().clearTextInput();
    }

    /**
     * Verify that conversation is scrolled to the end by verifying that plus
     * button and text input is visible
     */
    @When("^I see conversation is scrolled to the end$")
    public void ISeeConversationIsScrolledToEnd() {
        assertThat("The input field state looks incorrect",
                getConversationViewPage().waitForCursorInputVisible());
    }

    /**
     * Verify whether shield icon is visible next to convo input field
     *
     * @param shouldNotSee equals to null if the shield should be visible
     */
    @Then("^I (do not )?see shield icon in the conversation view$")
    public void ISeeShieldIcon(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The shield icon is not visible",
                    getConversationViewPage().isShieldIconVisible());
        } else {
            assertThat("The shield icon is visible, but should be hidden",
                    getConversationViewPage().isShieldIconInvisible());
        }
    }

    /**
     * Verify that the "You called" notification is shown
     */
    @Then("^I see \"You called\" notification in conversation view$")
    public void ISeeYouCalledNotification() {
        assertThat("\"You called\" message is not shown", getConversationViewPage().
                isYouCalledMessageVisible());
    }

    private static final double MAX_SIMILARITY_THRESHOLD = 0.985;

    /**
     * Verify whether the particular picture is animated
     */
    @Then("^I see the picture in the conversation view is animated$")
    public void ISeePictureIsAnimated() {
        final int maxFrames = 4;
        final double avgThreshold = ImageUtil.getAnimationThreshold(
                getConversationViewPage()::getRecentPictureScreenshot, maxFrames, Timedelta.ofMillis(0));
        assertThat(String.format("The picture in the conversation view seems to be static (%.2f >= %.2f)",
                avgThreshold, MAX_SIMILARITY_THRESHOLD), avgThreshold < MAX_SIMILARITY_THRESHOLD);
    }

    @When("^I tap file transfer option for 80 MB file")
    public void iTapFileTransferOptionFor80MBFile() {
        getConversationViewPage().tapFileTransferOptionFor80MBFile();
    }

    @When("^I tap file transfer option to send CountryCodes.plist file$")
    public void iTapFileTransferOptionForCountryCodes() {
        getConversationViewPage().tapFileTransferOptionForCountryCodesFile();
    }

    /**
     * Verify file transfer placeholder visibility
     *
     * @param shouldNotBeVisible equals to null if the placeholder should be visible
     */
    @When("^I (do not )?see file transfer placeholder$")
    public void ISeeFileTransferPlaceHolder(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("File transfer placeholder is not visible",
                    getConversationViewPage().isFileTransferTopLabelVisible() &&
                            getConversationViewPage().isFileTransferBottomLabelVisible());
        } else {
            assertThat("File transfer placeholder is visible, but should be hidden",
                    getConversationViewPage().isFileTransferTopLabelInvisible());
        }
    }

    /**
     * Tap on file transfer action button to download/preview file
     */
    @When("^I tap file transfer action button until File Actions menu is visible$")
    public void ITapFileTransferActionButton() {
        getConversationViewPage().tapFileTransferActionButton();
    }

    /**
     * Verify whether File Transfer placeholder is visible in the conversation view
     */
    @Then("^I wait up to (\\d+) seconds? until the file (.*) with size (.*) is ready for download from conversation view$")
    public void IWaitUntilDownloadFinished(int timeoutSeconds, String expectedFilename, String expectedSize) {
        assertThat(String.format(
                        "Cannot detect the Download Finished placeholder for a file '%s' in the conversation view after %s seconds",
                        expectedFilename, timeoutSeconds),
                getConversationViewPage().waitUntilDownloadReadyPlaceholderVisible(expectedFilename, expectedSize,
                        Timedelta.ofSeconds(timeoutSeconds)));
    }

    @When("^I tap default message in conversation view$")
    public void iTapOnDefaultTextMessage() {
        getConversationViewPage().tapMessageByText(DEFAULT_AUTOMATION_MESSAGE);
    }

    @When("^I long tap default message in conversation view$")
    public void iLongTapOnDefaultTextMessage() {
        getConversationViewPage().longTapMessageByText(DEFAULT_AUTOMATION_MESSAGE);
    }

    @When("^I long tap \"(.*)\" message in conversation view$")
    public void iLongTapTextMessage(String msg) {
        msg = context.getUsersManager().replaceAliasesOccurrences(msg, ClientUsersManager.FindBy.NAME_ALIAS);
        getConversationViewPage().longTapMessageByText(msg);
    }

    /**
     * Tap pointed control button
     */
    @When("^I tap Send record control button$")
    public void ITapSendRecordControlButton() {
        getConversationViewPage().tapSendRecordControlButton();
    }

    @When("^I tap on image in conversation view$")
    public void iTapImageInConversationView() {
        getConversationViewPage().tapImageInConversation();
    }

    @When("^I long tap on image in conversation view$")
    public void iLongTapImageInConversationView() {
        getConversationViewPage().longTapImageInConversation();
    }

    @When("^I long tap on file transfer placeholder in conversation view$")
    public void ILongTapFileTransferPlaceholder() {
        getConversationViewPage().longTapFileTransferPlaceholder();
    }

    @When("^I tap on file transfer placeholder in conversation view$")
    public void ITapFileTransferPlaceholder() {
        getConversationViewPage().tapFileTransferPlaceholder();
    }

    @When("^I tap Play audio message button$")
    public void iTapAudioMessagePlayButton() {
        getConversationViewPage().tapAudioMessagePlayButton();
    }

    @When("^I long tap on audio message placeholder in conversation view$")
    public void ILongTapAudioMessagePlaceholder() {
        getConversationViewPage().longTapPlayAudioMessageButton();
    }

    @When("^I tap on video message in conversation view$")
    public void ITapVideoMessage() {
        getConversationViewPage().tapVideoMessage();
    }

    @When("^I long tap on video message in conversation view$")
    public void ILongTapVideoMessage() {
        getConversationViewPage().longTapVideoMessage();
    }

    @When("^I tap on location map in conversation view$")
    public void ITapLocationMessage() {
        getConversationViewPage().tapLocationMap();
    }

    @When("^I long tap on link preview in conversation view$")
    public void ILongTapLinkPreview() {
        getConversationViewPage().longTapLinkPreview();
    }

    @When("^I tap on Youtube preview in conversation view$")
    public void ITapYoutubePreviewLink() {
        getConversationViewPage().singleTapYoutubePreview();
    }

    /**
     * Verify play/pause button state in audio message placeholder
     *
     * @param buttonState      play or pause
     */
    @Then("^I see state of button on audio message placeholder is (play|Play)$")
    public void ISeeAudioMessageControlButtonStateIs(String buttonState) {
        boolean isStateCorrect = getConversationViewPage().isPlaceholderAudioMessageButtonState(buttonState);
        assertThat(String.format("Wrong button state. The expected state is '%s'", buttonState),
                isStateCorrect);
    }

    @Then("^I see state of button on audio message placeholder is Pause$")
    public void iSeeAudioMessageControlButtonStatePause() {
        assertThat("Wrong button state",
                getConversationViewPage().isAudioMessagePauseButtonVisible());
    }

    @Then("^I (do not )?see video message container in the conversation view$")
    public void ISeeVideoMessageContainer(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("video message container is not visible",
                    getConversationViewPage().isVideoMessageVisible());
        } else {
            assertThat("video message container is visible, but should be hidden",
                    getConversationViewPage().isVideoMessageInvisible());
        }
    }

    @Then("^I (do not )?see audio message container in the conversation view$")
    public void ISeeAudioMessageContainer(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("audio message container is not visible",
                    getConversationViewPage().isAudioMessageVisible());
        } else {
            assertThat("audio message container is visible, but should be hidden",
                    getConversationViewPage().isAudioMessageInvisible());
        }
    }

    @Then("^I (do not )?see location map container in the conversation view$")
    public void ISeeLocationMapContainer(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("location map container is not visible",
                    getConversationViewPage().isLocationMapVisible());
        } else {
            assertThat("location map container is visible, but should be hidden",
                    getConversationViewPage().isLocationMapInvisible());
        }
    }

    @Then("^I (do not )?see link preview container in the conversation view$")
    public void ISeeLinkPreviewContainer(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Link preview container is not visible",
                    getConversationViewPage().isLinkPreviewVisible());
        } else {
            assertThat("Link preview container is visible, but should be hidden",
                    getConversationViewPage().isLinkPreviewInvisible());
        }
    }

    /**
     * Verify link preview image visibility
     *
     * @param shouldNotBeVisible equals to null if the placeholder should be visible
     */
    @When("^I (do not )?see link preview image in the conversation view$")
    public void ISeeLinkPreviewImage(String shouldNotBeVisible) {
        if (shouldNotBeVisible == null) {
            assertThat("Link preview image is not visible",
                    getConversationViewPage().isLinkPreviewImageVisible());
        } else {
            assertThat("Link preview image is visible, but should be hidden",
                    getConversationViewPage().isLinkPreviewImageInvisible());
        }
    }

    @When("^I tap Confirm button on Edit control")
    public void ITapConfirmEditControlButton() {
        getConversationViewPage().tapConfirmEditControlButton();
    }

    @When("^I tap Cancel button on Edit control")
    public void ITapCancelEditControlButton() {
        getConversationViewPage().tapCancelEditControlButton();
    }

    private static final Timedelta LIKE_ICON_STATE_CHANGE_TIMEOUT = Timedelta.ofSeconds(7); //seconds
    private static final double LIKE_ICON_MIN_SIMILARITY = 0.9999;

    /**
     * Store the current state of Like icon
     */
    @When("^I remember the state of (?:Like|Unlike) icon in the conversation$")
    public void IRememberLikeIconState() throws Exception {
        context.setLikeIconState(() -> getConversationViewPage().getLikeIconState());
    }

    /**
     * Verify whether the current state of Like icon differs from the previously remembered one
     *
     * @param shouldNotChange equals to null if the state should be changed
     */
    @Then("^I see the state of (?:Like|Unlike) icon is (not )?changed in the conversation$")
    public void IVerifyLikeIconState(String shouldNotChange) throws Exception {
        boolean condition;
        if (shouldNotChange == null) {
            condition = context.getLikeIconState().isChanged(LIKE_ICON_STATE_CHANGE_TIMEOUT, LIKE_ICON_MIN_SIMILARITY);
        } else {
            condition = context.getLikeIconState().isNotChanged(LIKE_ICON_STATE_CHANGE_TIMEOUT, LIKE_ICON_MIN_SIMILARITY);
        }
        assertThat(String.format("Like icon state is expected %s in %s seconds",
                        (shouldNotChange == null) ? "to be changed" : "to be not changed", LIKE_ICON_STATE_CHANGE_TIMEOUT),
                condition);
    }

    /**
     * Tap Like/Unlike icon in the conversation
     */
    @When("^I tap (?:Like|Unlike) icon in the conversation$")
    public void ITapLikeIcon() {
        getConversationViewPage().tapLikeIcon();
    }

    /**
     * Verify visibility of the Like/Unlike icon
     *
     * @param shouldNotSee eqauls to null if the icon should be visible
     */
    @Then("^I (do not )?see (?:Like|Unlike) icon in the conversation$")
    public void ISeeLikeIcon(String shouldNotSee) {
        boolean condition;
        if (shouldNotSee == null) {
            condition = getConversationViewPage().isLikeIconVisible();
        } else {
            condition = getConversationViewPage().isLikeIconInvisible();
        }
        assertThat(String.format("The Like/Unlike icon is expected to be %s",
                (shouldNotSee == null) ? "visible" : "invisible"), condition);
    }

    /**
     * Tap the toolbox of the recent message to open likers list
     */
    @When("^I tap toolbox of the recent message$")
    public void ITapMessageToolbox() {
        getConversationViewPage().tapRecentMessageToolbox();
    }

    /**
     * Tap the recent media container to show/hide like icon
     *
     * @param pWidth  destination cell X tap point (in percent 0-100)
     * @param pHeight destination cell Y tap point (in percent 0-100)
     */
    @When("^I tap at (\\d+)% of width and (\\d+)% of height of the recent message$")
    public void ITapAtContainerCorner(int pWidth, int pHeight) {
        getConversationViewPage().tapAtRecentMessage(pWidth, pHeight);
    }

    @When("^I tap at deep link message$")
    public void ITapAtDeepLinkMessage() {
        getConversationViewPage().tapAtDeepLinkMessage();
    }

    /**
     * Verify whether the particular text is present or not on message toolbox
     *
     * @param shouldNotSee equals to null if the text should be visible
     * @param expectedText part of the text to verify for presence
     */
    @Then("^I (do not )?see \"(.*)\"( button)? on the message toolbox in conversation view$")
    public void ISeeTextOnToolbox(String shouldNotSee, String expectedText, String button) {
        expectedText = context.getUsersManager()
                .replaceAliasesOccurrences(expectedText, FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            if (button == null) {
                assertThat(
                        String.format("The expected '%s' text is not visible on the message toolbox", expectedText),
                        getConversationViewPage().isMessageToolboxTextVisible(expectedText)
                );
            } else {
                assertThat(
                        String.format("The expected '%s' text is not visible on the message toolbox button", expectedText),
                        getConversationViewPage().isMessageToolboxButtonVisible(expectedText));
            }
        } else {
            if (button == null) {
                assertThat(
                        String.format("The expected '%s' text should not be visible on the message toolbox", expectedText),
                        getConversationViewPage().isMessageToolboxTextInvisible(expectedText)
                );
            } else {
                assertThat(
                        String.format("The expected '%s' text should not be visible on the message toolbox button", expectedText),
                        getConversationViewPage().isMessageToolboxButtonInvisible(expectedText));
            }
        }
    }

    /**
     * Set ephemeral messages timer to a corresponding value
     *
     * @param value one of available timer values
     */
    @When("^I set self deleting message expiration timer to (Off|10 seconds|5 minutes) on conversation view$")
    public void ISetExpirationTimer(String value) {
        getConversationViewPage().setMessageExpirationTimer(value);
    }

    @Then("^I (do not )?see Has Guests banner in conversation view$")
    public void ISeeBannerHasGuests(String shouldNotSee) {
        String bannerType = "Has Guests";
        if (shouldNotSee == null) {
            assertThat("Has Guests banner is expected to be visible",
                    getConversationViewPage().isConversationHasGuestsVisible());
        } else {
            assertThat(String.format("'Has %s' banner is not expected to be visible", bannerType),
                    getConversationViewPage().isConversationHasGuestsInvisible());
        }
    }

    /**
     * Check if the last message in the conversation view contains a reply
     *
     * @param shouldNotSee there should be no reply visible if this string is not null
     */
    @Then("^I (do not )?see the last message in conversation view contains a reply$")
    public void iSeeTheLastMessageInConversationViewContainsAReply(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The conversation view does not contain a reply",
                    getConversationViewPage().isReplyVisible());
        } else {
            assertThat("The quote should not be visible in input field",
                    getConversationViewPage().isReplyInvisible());
        }
    }

    @Then("^I (do not )?see the input field$")
    public void IDoNotSeeTheInputField(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The input field is not visible",
                    getConversationViewPage().isInputFieldVisible());
        } else {
            assertThat("The input field should not be visible",
                    getConversationViewPage().isInputFieldInvisible());
        }
    }

    /**
     * Check if the message that is being replied to is of a certain type
     *
     * @param expectedElement the expected type of the message that is quoted
     */
    @Then("^I see that I'm replying to an? (Image|Video|Audio|File) message$")
    public void iSeePictureInQuoteAboveTextInputField(String expectedElement) {
        assertThat(String.format("The input field quote does not contain an '%s' message",
                expectedElement), getConversationViewPage().isInputFieldQuoteOfTypeVisible(expectedElement));
    }

    @Then("^I see reply to quoted Image in conversation view$")
    public void iSeeImageReplyInConversationView() {
        assertThat("Image in reply is NOT visible",
                getConversationViewPage().isQuotedImageVisible());
    }

    /**
     * Check if the message that has been quoted contains text
     *
     * @param expectedMessage the expected text of the quoted message
     */
    @Then("^I see the quoted message contains text \"(.*)\"$")
    public void iSeeReplyTextInQuotedMessage(String expectedMessage) {
        assertThat("The text '%s' is not present in the quoted message",
                getConversationViewPage().isQuotedMessageVisible(expectedMessage));
    }

    /**
     * Checks for the number of reply cells visible in conversation view
     *
     * @param numberOfReplies the number of replies that should be in conversation view
     */
    @Then("^I see (\\d+) (?:reply|replies) in the conversation view$")
    public void iSeeTheNumberOfReplies(int numberOfReplies) {
        assertThat(String.format("The number of replies in conversation view is not '%s'", numberOfReplies),
                getConversationViewPage().isNumberOfReplyCellsVisible(numberOfReplies));
    }

    /**
     * check if the recent message is seen by x amount of users
     * NOTE: does not work when the time of reading is shown
     *
     * @param persons the amount of users
     */
    @Then("^I see that recent message is seen by (\\d+) persons?$")
    public void iSeeThatRecentMessageIsSeenByPerson(int persons) {
        assertThat(String.format("The message is not seen by '%s' persons", persons),
                getConversationViewPage().isMessageDeliveryStatusTextVisible(Integer.toString(persons)));
    }

    /**
     * checks if text is visible in the message details part of the message toolbox
     *
     * @param doNot  wether or not it should be visible
     * @param status the text that should or should not be visible in the details part of the message toolbox
     */
    @Then("^I (do not )?see message details (.*) in message toolbox$")
    public void iDoNotSeeTheMessageDetailsInToolbox(String doNot, String status) {
        if (doNot == null) {
            assertThat(String.format("The delivery status does not contain '%s'", status), getConversationViewPage().isMessageToolboxDetailsTextVisible(status));
        } else {
            assertThat(String.format("The delivery status does contain '%s' while it should not", status), getConversationViewPage().isMessageToolboxDetailsTextInvisible(status));
        }
    }

    /**
     * checks is the delivery status is visible in the message toolbox
     *
     * @param doNot wether or not it should be visible
     */
    @Then("^I (do not )?see the delivery status in message toolbox$")
    public void iDoNotSeeTheDeliveryStatusInMessageToolbox(String doNot) {
        if (doNot == null) {
            assertThat("The delivery status is not visible", getConversationViewPage().isMessageDeliveryStatusVisible());
        } else {
            assertThat("The delivery status is visible while it should not be", getConversationViewPage().isMessageDeliveryStatusInvisible());
        }
    }

    /**
     * I see the legal hold indicator next to self title in Conversation View
     *
     * @param shouldNotSee equals to null if the element should be visible
     */
    @Then("^I (do not )?see legal hold indicator next to conversation title in conversation view$")
    public void iSeeLegalHoldIndicatorNextToConversationTitle(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The legal hold indicator is not visible next to conversation title in conversation view",
                    getConversationViewPage().isLegalHoldIndicatorVisible());
        } else {
            assertThat("The legal hold indicator is visible next to conversation title in conversation view while it should not be",
                    getConversationViewPage().isLegalHoldIndicatorInvisible());
        }
    }

    @When("^I see an image with QR code \"(.*)\" in the conversation view$")
    public void iSeeImageInConversation(String qrCode) {
        BufferedImage actualImage = getConversationViewPage().getRecentPictureScreenshot().get();
        context.addAdditionalScreenshots(actualImage);

        assertThat("Could not find correct QR code",
                getConversationViewPage().getQRCodeFromPicture(),
                hasItem(qrCode));
    }

    @Then("^I see (.*) reaction in the conversation view$")
    public void ISeeReactionX(String reaction) {
        assertThat(String.format("Reaction %s is not visible", reaction), getConversationViewPage().isReactionVisible(reaction));
    }

    @Then("^I do not see (.*) reaction in the conversation view$")
    public void IDoNotSeeReactionX(String reaction) {
        assertThat(String.format("Reaction %s is visible", reaction), getConversationViewPage().isReactionInvisible(reaction));
    }


    @Then("^I see User (.*) will get your message later in conversation view$")
    public void iSeeUserWillGetYourMessageLater(String usernameAlias) {
        String name = context.getUsersManager()
                .replaceAliasesOccurrences(usernameAlias, FindBy.NAME_ALIAS);
        assertThat(String.format("User %s will get your message later is not visible", name), getConversationViewPage().isUserWillGetYourMessageLaterVisible(name));
    }

    @Then("^I tap on Learn more link on delayed message in conversation view$")
    public void ITapOnLearnMoreLinkOnDelayedMessage() {
        getConversationViewPage().iTapOnLearnMoreLinkOnDelayedMessage();
    }

    @Then("^I do not see Enterprise Upgrade alert$")
    public void IDoNotSeeEnterpriseUpgradeAlert() {
        assertThat(getConversationViewPage().enterpriseUpgradeAlertPresent(), is(false));
    }
}
