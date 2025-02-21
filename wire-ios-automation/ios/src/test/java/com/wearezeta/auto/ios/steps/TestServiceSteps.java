package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.CommonSteps;
import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.Config;
import com.wearezeta.auto.common.backend.models.ReactionType;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.EphemeralTimeConverter;
import com.wearezeta.auto.common.testservice.models.LegalHoldStatus;
import com.wearezeta.auto.common.imagecomparator.QRCode;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import javax.imageio.ImageIO;
import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.file.Files;
import java.util.concurrent.*;
import java.util.logging.Logger;

import static com.wearezeta.auto.common.CommonSteps.*;

public class TestServiceSteps {

    private static final Logger log = ZetaLogger.getLog(TestServiceSteps.class.getSimpleName());
    IOSTestContext context;

    public TestServiceSteps(IOSTestContext context) {
        this.context = context;
    }

    private CommonSteps getCommonSteps() {
        return context.getCommonSteps();
    }

    private ClientUsersManager getUsersManager() {
        return context.getUsersManager();
    }

    @When("^User (.*) deletes? (everywhere )?the recent message from (?:user|group conversation) (.*)$")
    public void UserXDeleteLastMessage(String userNameAlias, String deleteEverywhere, String dstNameAlias) {
        getCommonSteps().userDeletesLatestMessage(userNameAlias, dstNameAlias, null,
                deleteEverywhere != null);
    }

    @When("^User (.*) shares? the default location to (?:user|group conversation) (.*) via device (.*)")
    public void UserXSharesLocationTo(String senderAlias, String convoName, String deviceName) {
        getCommonSteps().userSendsLocationToConversation(senderAlias, convoName, deviceName,
                context.getSelfDeletingMessageTimeout(senderAlias, convoName),
                0, 0, "location", 1);
    }

    @When("^User (.*) sends (.*) sized file with MIME type (.*) and name (.*)(?: via device (.*))? to conversation (.*)$")
    public void iXSizedSendFile(String contact, String size, String mimeType, String fileName, String deviceName,
                                String dstConvoName) throws Exception {
        String path = Files.createTempDirectory("zautomation")
                .toAbsolutePath().toString().replace("%40", "@");
        RandomAccessFile f = new RandomAccessFile(path + "/" + fileName, "rws");
        int fileSize = Integer.valueOf(size.replaceAll("\\D+", "").trim());
        if (size.contains("MB")) {
            f.setLength(fileSize * 1024 * 1024);
        } else if (size.contains("KB")) {
            f.setLength(fileSize * 1024);
        } else {
            f.setLength(fileSize);
        }
        f.close();
        context.startPinging();
        context.getCommonSteps().userSendsFileToConversation(contact, dstConvoName,
                deviceName, context.getCommonSteps().getEphemeralTimeout(contact, dstConvoName),
                path + "/" + fileName, mimeType);
        context.stopPinging();
    }

    @Deprecated // Please use above step instead for sending "temporary" files
    @When("^User (.*) sends? (temporary )?file (.*) having MIME type (.*) to (?:single user|group) conversation (.*) using " +
            "device (.*)$")
    public void UserSendsFile(String sender, String isTemporary, String fileName, String mimeType,
                              String convoName, String deviceName) {
        String root;
        if (isTemporary == null) {
            if (mimeType.toLowerCase().contains("audio")) {
                // send audio with metadata through ETS
                root = Config.current().getAudioPath(getClass());
                context.getCommonSteps().userSendsAudioToConversation(sender, convoName, deviceName,
                        context.getSelfDeletingMessageTimeout(sender, convoName), root + File.separator + fileName, mimeType, Timedelta.ofSeconds(15));
            } else if (mimeType.toLowerCase().contains("video")) {
                // Send video with metadata through ETS
                root = Config.current().getVideoPath(getClass());
                context.getCommonSteps().userSendsVideoToConversation(sender, convoName, deviceName,
                        context.getSelfDeletingMessageTimeout(sender, convoName), root + File.separator + fileName, mimeType, Timedelta.ofSeconds(15), new int[]{800,600});
            } else {
                //send file without ETS metadata
                if (mimeType.toLowerCase().contains("image")) {
                    root = Config.current().getImagesPath(getClass());
                } else {
                    root = Config.current().getAudioPath(getClass());
                }
                getCommonSteps().userSendsFileToConversation(sender, convoName, deviceName,
                        context.getSelfDeletingMessageTimeout(sender, convoName),root + File.separator + fileName,
                        mimeType);
            }
        } else {
            // send temporary file
            root = Config.current().getBuildPath(getClass());
            getCommonSteps().userSendsFileToConversation(sender, convoName, deviceName,
                    context.getSelfDeletingMessageTimeout(sender, convoName), root + File.separator + fileName,
                    mimeType);
        }
    }

    @Given("^Users? adds? the following devices?: (.*)")
    public void UsersAddDevices(String mappingAsJson)  {
        getCommonSteps().usersAddDevices(mappingAsJson, false);
    }

    @Given("^Users? of team owned by (.*) adds? the following 2FA devices?: (.*)")
    public void UsersAddDevices(String teamOwnerAlias, String mappingAsJson)  {
        getCommonSteps().usersAdd2FADevices(teamOwnerAlias, mappingAsJson);
    }

    @Given("^User (\\w+) pings conversation (.*)")
    public void UserPingedConversation(String pingFromUserNameAlias, String dstConversationName) {
        getCommonSteps().userPingsConversation(pingFromUserNameAlias, dstConversationName,
                FIRST_AVAILABLE_DEVICE,  context.getSelfDeletingMessageTimeout(pingFromUserNameAlias, dstConversationName));
    }

    @Given("^User (.*) sends? (\\d+) messages? using device (.*) to (?:user|group conversation) (.*)$")
    public void userSendXMessagesToConversationUsingDevice(String msgFromUserNameAlias,
                                                           int msgsCount, String deviceName,
                                                           String conversationName) {
        for (int i = 0; i < msgsCount; i++) {
            getCommonSteps().userSendsGenericMessageToConversation(msgFromUserNameAlias, conversationName,
                    deviceName, context.getSelfDeletingMessageTimeout(msgFromUserNameAlias, conversationName),
                    DEFAULT_AUTOMATION_MESSAGE, LegalHoldStatus.DISABLED);
        }
    }

    @Given("^User (.*) (sets|changes) the unique username( to \".*\")?$")
    public void userSetsUniqueUsername(String userAs, String action, String uniqueUsername) {
        switch (action.toLowerCase()) {
            case "sets":
                getCommonSteps().usersSetUniqueUsername(userAs);
                break;
            case "changes":
                if (uniqueUsername == null) {
                    throw new IllegalArgumentException("Unique username is mandatory to set");
                }
                // Exclude quotes
                uniqueUsername = uniqueUsername.substring(5, uniqueUsername.length() - 1);
                uniqueUsername = getUsersManager().replaceAliasesOccurrences(uniqueUsername,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
                getCommonSteps().userChangesUniqueUsername(userAs, uniqueUsername);
                break;
            default:
                throw new IllegalArgumentException(String.format("Unknown action '%s'", action));

        }
    }

    @When("^User (.*) (likes|unlikes|received) the recent message from (?:user|group conversation) (.*)$")
    @Deprecated // Use step to toggle reaction instead
    public void userReactLastMessage(String userNameAlias, String reactionType, String dstNameAlias) {
        switch (reactionType.toLowerCase()) {
            case "likes":
                getCommonSteps().userReactsToLatestMessage(userNameAlias, dstNameAlias, null,
                        ReactionType.LIKE);
                break;
            case "unlikes":
                getCommonSteps().userReactsToLatestMessage(userNameAlias, dstNameAlias, null,
                        ReactionType.UNLIKE);
                break;
            case "received":
                getCommonSteps().userSendsDeliveryConfirmationForLastEphemeralMessage(userNameAlias, dstNameAlias, null);
                break;
            default:
                throw new IllegalArgumentException(String.format("Cannot identify the reaction type '%s'",
                        reactionType));
        }
    }

    @Then("^User (.*) marks the recent message as read in conversation (.*) via device (.*)$")
    public void userMarksMessageRead(String receiverAlias, String convoName, String deviceName) {
        getCommonSteps().userSendsReadConfirmationForRecentMessage(receiverAlias, convoName, deviceName);
    }

    @Given("^User (.*) sends (\\d+) (image|video|audio|temporary) files? (.*) to conversation (.*)")
    public void UserSendsMultiplePictures(String senderUserNameAlias, int count,
                                          String fileType, String fileName,
                                          String dstConversationName) {
        getCommonSteps().userSendsMultipleMedias(senderUserNameAlias, dstConversationName,
                context.getSelfDeletingMessageTimeout(senderUserNameAlias, dstConversationName),
                count, fileType, fileName);
    }

    @Given("^User (.*) sends image with QR code containing \"(.*)\" to conversation (.*)")
    public void WhenUserSendQRImageToConv(String senderUserNameAlias, String text, String dstConversationName) throws IOException {
        File tempFile = File.createTempFile("zautomation", ".png");
        tempFile.deleteOnExit();
        ImageIO.write(QRCode.generateCode(text, Color.BLACK, Color.WHITE, 500, 1), "png", tempFile);
        getCommonSteps().userSendsImageToConversationViaTestservice(senderUserNameAlias, dstConversationName, FIRST_AVAILABLE_DEVICE, tempFile.getPath(),
                context.getSelfDeletingMessageTimeout(senderUserNameAlias, dstConversationName));
    }

    @Given("^User (.*) sends (\\d+) (default|long|\".*\") messages? to conversation (.*)")
    public void UserSendsMultipleMessages(String senderUserNameAlias, int count,
                                          String msg, String dstConversationName) {
        context.startPinging();
        try {
            getCommonSteps().userSendsMultipleMessages(senderUserNameAlias, dstConversationName,
                    context.getSelfDeletingMessageTimeout(senderUserNameAlias, dstConversationName),
                    count, msg, DEFAULT_AUTOMATION_MESSAGE, LegalHoldStatus.DISABLED);
        } finally {
            context.stopPinging();
        }
    }

    @Given("^User (.*) sends invite link for conversation (.*) message to conversation (.*)")
    public void UserSendsInviteLinkForConversationMessageToConversation(String senderUserNameAlias, String conversationTitle, String dstConversationName) {
        String msg = getCommonSteps().getInviteLinkOfConversation(senderUserNameAlias, conversationTitle);

        context.startPinging();
        try {
            getCommonSteps().userSendsMultipleMessages(senderUserNameAlias, dstConversationName,
                    context.getSelfDeletingMessageTimeout(senderUserNameAlias, dstConversationName),
                    1, msg, DEFAULT_AUTOMATION_MESSAGE, LegalHoldStatus.DISABLED);
        } finally {
            context.stopPinging();
        }
    }

    @Given("^User (.*) sends link preview for \"(.*)\" to conversation (.*)")
    public void userSendsLinkPreview(String senderUserNameAlias, String url, String dstConversationName)
            throws IOException {
        context.startPinging();
        try {
            File tempFile = File.createTempFile("zautomation", ".png");
            try {
                ImageIO.write(QRCode.generateCode(url, Color.BLACK, Color.WHITE, 64, 1),
                        "png", tempFile);
                getCommonSteps().userSendsLinkPreview(senderUserNameAlias, dstConversationName, null,
                        Timedelta.ofMillis(0), url, "Link preview for " + url, tempFile.getAbsolutePath());
            } finally {
                tempFile.delete();
            }
        } finally {
            context.stopPinging();
        }
    }

    @Given("^User (.*) sends (\\d+) (default|long|\".*\") messages? under (legal hold|unknown state) to conversation (.*)")
    public void UserSendsMultipleMessagesUnderLegalHold(String senderUserNameAlias, int count,
                                          String msg, String status, String dstConversationName) {
        if (status.equals("legal hold")) {
            getCommonSteps().userSendsMultipleMessages(senderUserNameAlias, dstConversationName,
                    context.getSelfDeletingMessageTimeout(senderUserNameAlias, dstConversationName),
                    count, msg, DEFAULT_AUTOMATION_MESSAGE, LegalHoldStatus.ENABLED);
        } else {
            getCommonSteps().userSendsMultipleMessages(senderUserNameAlias, dstConversationName,
                    context.getSelfDeletingMessageTimeout(senderUserNameAlias, dstConversationName),
                    count, msg, DEFAULT_AUTOMATION_MESSAGE, LegalHoldStatus.UNKNOWN);
        }
    }

    @When("^User (.*) sends delivery confirmation for the recent message in (.*) conversation")
    public void userSendsDeliveryConfirmationForRecentMessage(String receiverAlias, String convoName) {
        getCommonSteps().userSendsDeliveryConfirmationForRecentMessage(receiverAlias, convoName,
                FIRST_AVAILABLE_DEVICE);
    }

    @When("^User (.*) sends poll message \"(.*)\" with title \"(.*)\" and buttons \"(.*)\"(?: via device (.*))? to conversation (.*)$")
    public void userSendPollMessageToConversation(String msgFromUserNameAlias,
                                                  String msg, String title, String buttons, String deviceName, String convoName) {
        context.startPinging();
        // We timeout after 2 minutes because ETS sometimes crashes
        final ExecutorService service = Executors.newSingleThreadExecutor();
        try {
            final Future f = service.submit(() -> {
                context.getCommonSteps().userSendsPollMessageToConversation(msgFromUserNameAlias, convoName,
                        deviceName, NO_EXPIRATION, msg, title, buttons,
                        LegalHoldStatus.DISABLED);
            });
            f.get(2, TimeUnit.MINUTES);
        } catch (final TimeoutException e) {
            log.severe("Sending poll message via Testservice timed out: " + e.getMessage());
        } catch (final Exception e) {
            log.severe("Sending poll message via Testservice failed: " + e.getMessage());
        } finally {
            service.shutdown();
            context.stopPinging();
        }
    }

    @When("^User (.*) sends button action confirmation to user (.*) on the latest poll(?: via device (.*))? in conversation (.*) with button \"(.*)\"$")
    public void userSendsButtonActionConfirmationOnPollMessage(String senderAlias, String receiverAlias, String deviceName, String dstConvoName, String buttonText) {
        context.startPinging();
        try {
            context.getCommonSteps().userSendsButtonActionConfirmationToLatestPollMessage(senderAlias, receiverAlias, deviceName, dstConvoName, buttonText);
        } finally {
            context.stopPinging();
        }
    }

    @Given("^User (.*) sends deep link for conversation (.*) to conversation (.*)")
    public void UserSendsDeepLink(String senderUserNameAlias, String srcConversationName, String dstConversationName) {
        String deeplink = getCommonSteps().getDeepLinkForConversation(srcConversationName, senderUserNameAlias);
        deeplink = CommonUtils.formatMarkdownURL("deep link", deeplink);
        getCommonSteps().userSendsMessageToConversation(senderUserNameAlias, dstConversationName,null,NO_EXPIRATION, deeplink, LegalHoldStatus.DISABLED);
    }

    @When("^User (.*) sends? ephemeral message \"?(.*?)\"?\\s? with timer (10 seconds|5 minutes|1 hour|1 day|1 week|4 weeks) (?:via device (.*)\\s)?to (user|group conversation) (.*)$")
    public void userSendEphemeralMessageToConversation(String msgFromUserNameAlias,
                                                       String msg, String msgTimer, String deviceName, String convotype, String dstConvoName) {
        long msgTimerInMs = EphemeralTimeConverter.asMillis(msgTimer);
        getCommonSteps().userSendsMessageToConversation(msgFromUserNameAlias, dstConvoName, deviceName,
                Timedelta.ofMillis(msgTimerInMs), msg, LegalHoldStatus.DISABLED);
    }

    @When("^User (.*) sends message \"(.*?)\" as reply to last message of conversation (.*) via device (.*)?$")
    public void userRepliesToLatestMessage(String senderAlias, String message, String conversationName, String deviceName) {
        getCommonSteps().userRepliesToLatestMessage(senderAlias, conversationName, deviceName, NO_EXPIRATION, message);
    }

    @When("^User (.*) sends message \"(.*?)\" as reply to the last message of conversation (.*)$")
    public void userRepliesToLatestMessage(String senderAlias, String message, String conversationName) {
        getCommonSteps().userRepliesToLatestMessage(senderAlias, conversationName, FIRST_AVAILABLE_DEVICE, NO_EXPIRATION, message);
    }

    @When("^User (.*) sends (\\d+) messages? \"(.*?)\" with mention to conversation (.*)$")
    public void userSendsMessageWithMentions(String msgFromUserNameAlias, int numberOfMessages, String msg, String dstConvoName) {
        msg = msg.replace("\\n", "\n");
        for (int i = 0; i < numberOfMessages; i++) {
            getCommonSteps().userSendsTextWithMentions(msgFromUserNameAlias, dstConvoName,
                    FIRST_AVAILABLE_DEVICE, NO_EXPIRATION, msg);
        }
    }
}
