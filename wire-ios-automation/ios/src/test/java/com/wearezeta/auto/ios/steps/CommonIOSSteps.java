package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.*;
import com.wearezeta.auto.common.backend.Backend;
import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.misc.EphemeralTimeConverter;
import com.wearezeta.auto.common.testservice.models.LegalHoldStatus;
import com.wearezeta.auto.common.imagecomparator.QRCode;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.common.Lifecycle;
import com.wearezeta.auto.ios.pages.CustomBackendRedirectionPage;
import com.wearezeta.auto.ios.pages.IOSPage;
import com.wire.qa.picklejar.engine.exception.SkipException;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.nio.file.Path;
import java.util.logging.Logger;

import static org.hamcrest.MatcherAssert.assertThat;

import org.openqa.selenium.ScreenOrientation;

import javax.imageio.ImageIO;
import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.Duration;
import java.text.ParseException;

import static org.hamcrest.Matchers.*;

public class CommonIOSSteps {

    IOSTestContext context;

    public CommonIOSSteps(IOSTestContext context) {
        this.context = context;
    }

    private static final Logger log = ZetaLogger.getLog(IOSPage.class.getSimpleName());

    private static final String SAFARI = "com.apple.mobilesafari";

    static {
        System.setProperty("org.apache.commons.logging.Log", "org.apache.commons.logging.impl.SimpleLog");
        System.setProperty("org.apache.commons.logging.simplelog.log.org.apache.http", "warn");
    }

    private CommonSteps getCommonSteps() {
        return context.getCommonSteps();
    }

    private IOSPage getCommonPage() {
        return context.getPagesCollection().getPage(IOSPage.class);
    }

    private CustomBackendRedirectionPage getCustomBackendRedirectionPage() {
        return context.getPagesCollection().getPage(CustomBackendRedirectionPage.class);
    }

    /**
     * Upgrade Wire to the recent version if the old one was previously installed
     */
    @Given("^I upgrade Wire to the recent version$")
    public void IUpgradeWire() {
        getCommonPage().installApp(new File(Lifecycle.getAppPath()));
        getCommonPage().activateApp(Lifecycle.getBundleId());
    }

    @Given("^I install the old version of Wire$")
    public void installOldWire() {
        getCommonPage().installApp(new File(Lifecycle.getOldAppPath()));
        getCommonPage().activateApp(Lifecycle.getBundleId());
    }

    @Given("^I point the app to production backend$")
    public void IStartOnProductionBackend() {
        context.startAppOnProductionBackend();
    }

    @Given("^All other versions of Wire are uninstalled$")
    public void IUninstallAllVersionsWire() {
        context.uninstallAllVersionsOfWire();
    }

    @Given("^I enroll the simulator for Touch ID$")
    public void iEnrollSimulatorTouchID() {
        context.enrollSimulatorTouchID();
    }

    /**
     * Restarts currently executed Wire instance
     */
    @When("^I restart Wire$")
    public void IRestartWire() {
        final String wireBundleId = Lifecycle.getBundleId();
        getCommonPage().terminateApp(wireBundleId);
        getCommonPage().activateApp(wireBundleId);
    }

    @When("^I terminate Wire$")
    public void ITerminateWire() {
        getCommonPage().terminateApp(Lifecycle.getBundleId());
    }

    @Given("^The device is reset before and after the test$")
    public void fullReset() {
        context.doFullReset();
    }

    // region permissions

    @Given("^I allow microphone access")
    public void iAllowMicrophoneAccess() {
        context.allowMicrophoneAccess();
    }

    @Given("^I allow camera access")
    public void iAllowCameraAccess() {
        context.allowCameraAccess();
    }

    @Given("^I allow access to all photos")
    public void iAllowAccessToAllPhotos() {
        context.allowAccessToAllPhotos();
    }

    // endregion permissions

    @When("^I accept camera access alert on real device$")
    public void iAcceptCameraAccessAlert() {
        if (context.isRealDevice()) {
            getCommonPage().acceptAlert();
        }
    }

    @When("^I accept microphone access alert on real device$")
    public void iAcceptMicrophoneAccessAlert() {
        if (context.isRealDevice()) {
            getCommonPage().acceptAlert();
        }
    }

    @When("^I accept access to all photos on real device$")
    public void iAcceptAccessToAllPhotos() {
        if (context.isRealDevice()) {
            getCommonPage().acceptAccessToAllPhotos();
        }
    }

    @When("^I accept alert( if visible)?$")
    public void IAcceptAlert(String mayIgnore) {
        if (mayIgnore == null) {
            getCommonPage().acceptAlert();
        } else {
            if (getCommonPage().acceptAlertIfVisible()) {
                log.info("Unexpected alert was present on " + context.getScenario().getName());
            } else {
                log.info("Unexpected alert was not present on " + context.getScenario().getName());
            }
        }
    }

    @When("^I tap Not Now on save password alert$")
    public void ITapNotNowPasswordSaveAlert() {
        if (getCommonPage().isNotNowOnPasswordPromptVisible()) {
            getCommonPage().tapNotNowOnPasswordPrompt();
        }
    }

    @When("^I accept notification permission alert if visible$")
    public void IAcceptNotificationAlert() {
      getCommonPage().acceptNotificationAlertIfVisible();
    }


    /**
     * Tap the corresponding on-screen keyboard button
     *
     * @param btnName button name
     */
    @When("^I tap (Hide|Space|Done|Next) keyboard button$")
    public void ITapHideKeyboardBtn(String btnName) {
        //sometimes the simulator doesn't show the keyboard up
        if (getCommonPage().isKeyboardVisible()) {
            switch (btnName.toLowerCase()) {
                case "hide":
                    getCommonPage().tapHideKeyboardButton();
                    break;
                case "space":
                    getCommonPage().tapSpaceKeyboardButton();
                    break;
                case "done":
                    getCommonPage().tapKeyboardCommitButton();
                    break;
                case "next":
                    getCommonPage().tapNextKeyboardButton();
                    break;
                default:
                    throw new IllegalArgumentException(String.format("Unknown button name: %s", btnName));
            }
        } else{
            log.warning("keyboard should be visible but it's not");
        }
    }

    /**
     * Closes the app for a certain amount of time in seconds
     *
     * @param seconds time in seconds to close the app
     */
    @When("^I minimize Wire for (\\d+) seconds?$")
    public void IMinimizeWire(int seconds) {
        getCommonPage().putWireToBackgroundFor(Timedelta.ofSeconds(seconds));
    }

    /**
     * Locks screen for a certain amount of time in seconds
     *
     * @param seconds time in seconds to lock screen
     */
    @When("^I lock screen for (\\d+) seconds?$")
    public void ILockScreen(int seconds) {
        getCommonPage().lockScreen(Timedelta.ofSeconds(seconds));
    }

    @Given("^There (?:is|are) (\\d+) users? where (.*) is me$")
    public void thereAreNUsersWhereXIsMe(int count, String myNameAlias) throws Exception {
        getCommonSteps().thereAreNPersonalUsersWhereXIsMe(count, myNameAlias);
        getCommonSteps().userChangesUserAvatarPicture(myNameAlias);
        getCommonSteps().usersSetUniqueUsername(myNameAlias);
    }

    /**
     * Creates specified number of users and sets user with specified name as
     * main user. The user is registered with a email only and has no phone
     * number attached
     */
    @Given("^There (?:are|is) (\\d+) users? with email address only where (.*) is me$")
    public void ThereAreNUsersWhereXIsMeWithoutPhone(int count, String myNameAlias) throws Exception {
        throw new RuntimeException("Phone number support was removed");
    }

    @When("^I wait for (\\d+) seconds?$")
    public void WaitForTime(int seconds) {
        context.startPinging();
        Timedelta.ofSeconds(seconds).sleep();
        context.stopPinging();
    }

    @Deprecated // Please try not to use this step. Replace Myself with explicit placeholders
    @Given("^User (.*) is [Mm]e$")
    public void UserXIsMe(String nameAlias) {
        getCommonSteps().userXIsMe(nameAlias);
    }

    @When("^I rotate UI to (landscape|portrait)$")
    public void WhenIRotateUILandscape(String orientation) {
        orientation = orientation.toUpperCase();
        getCommonPage().rotateScreen(ScreenOrientation.valueOf(orientation));
        Timedelta.ofSeconds(1).sleep();
    }

    /**
     * Tap at the corresponding point of the visible viewport
     *
     * @param percentX 0 <= percentX <= 100
     * @param percentY 0 <= percentY <= 100
     */
    @When("^I tap at (\\d+)%,(\\d+)% of the viewport size")
    public void ITapAtPoint(int percentX, int percentY) {
        getCommonPage().tapScreenByPercents(percentX, percentY);
    }

    @Deprecated // Please use alert title or alert description steps
    @Then("^I (do not )?see alert contains text \"(.*)\"$")
    public void ISeeAlertContains(String shouldNotBeVisible, String expectedText) {
        if (shouldNotBeVisible == null) {
            assertThat(String.format("There is no '%s' text on the alert", expectedText),
                    getCommonPage().isAlertContainsText(expectedText));
        } else {
            assertThat(String.format("There is '%s' text on the alert", expectedText),
                    getCommonPage().isAlertDoesNotContainsText(expectedText));
        }
    }

    @Then("^I see alert title contains text \"(.*)\"$")
    public void ISeeAlertTitleContains(String expectedText) {
        assertThat("Wrong alert title", getCommonPage().getAlertTitle(), containsString(expectedText));
    }

    @Then("^I see alert description contains text \"(.*)\"$")
    public void ISeeAlertDescriptionContains(String expectedText) {
        assertThat("Wrong alert description", getCommonPage().getAlertDescription(),
                containsString(expectedText));
    }

    @And("^I type \"(.*)\" text into the alert input field$")
    public void iTypeInAlertInput(String text) {
        // Wait until alert visible
        text = context.getUsersManager()
                .replaceAliasesOccurrences(text, ClientUsersManager.FindBy.PASSWORD_ALIAS);
        getCommonPage().typeAlertText(text);
    }

    @And("^I tap (.*) button on the alert$")
    public void iTapAlertButton(String caption) {
        getCommonPage().tapAlertButton(caption);
    }

    @And("^I (do not )?see (.*) button on the alert$")
    public void iSeeAlertButton(String shouldNotSee, String caption) {
        if (shouldNotSee == null) {
            assertThat(String.format("The '%s' button is not visible on the alert", caption), getCommonPage().isAlertButtonVisible(caption));
        } else {
            assertThat(String.format("The '%s' button is visible on the alert while it should not be", caption),
                    not(getCommonPage().isAlertButtonVisible(caption)));
        }
    }

    /**
     * Create random file in project.build.directory folder for further usage
     *
     * @param size file size. Can be float value. Example: 1MB, 2.00KB
     * @param name file name without extension
     * @param ext  file extension
     */
    @Given("^I create temporary file (.*) in size with name \"(.*)\" and extension \"(.*)\"$")
    public void ICreateTemporaryFile(String size, String name, String ext) {
        final String tmpFilesRoot = Config.current().getBuildPath(getClass());
        CommonUtils.createRandomAccessFile(String.format("%s%s%s.%s", tmpFilesRoot, File.separator, name, ext), size);
    }

    // Check ZIOS-6570 for more details
    private static final String SIMULATOR_VIDEO_MESSAGE_PATH = "/var/tmp/video.mp4";

    /**
     * Prepares the existing video file to be uploaded by iOS simulator
     *
     * @param name the name of an existing file. The file should be located in tools/img folder
     */
    @Given("^I prepare (.*) to be uploaded as a video message$")
    public void IPrepareVideoMessage(String name) {
        final File srcVideo = new File(Config.current().getVideoPath(getClass()) + File.separator + name);
        if (!srcVideo.exists()) {
            throw new IllegalArgumentException(String.format("The file %s does not exist or is not accessible",
                    srcVideo.getAbsolutePath()));
        }
        final String path = srcVideo.toPath().toString();

        getCommonPage().pushFile(name, path);
    }

    @Given("^I push image with QR code containing \"Image\" to camera roll$")
    public void iPushImageWithQRCode() throws IOException {
        final Path directory = Files.createTempDirectory("zautomation");
        final String qrcode = "Image";
        final String fileFormat = "png";
        String fileName = String.format("%s.%s", qrcode, fileFormat);
        final File tempFile = new File(directory.toAbsolutePath() + File.separator + fileName);
        tempFile.deleteOnExit();
        ImageIO.write(QRCode.generateCode(qrcode, Color.BLACK, Color.WHITE, 500, 4), fileFormat, tempFile);
        if (!getCommonPage().doesFileExistOnDevice(fileName)) {
            log.info(String.format(
                    "File named %s not found on device. Pushing %s...",
                    fileName,
                    tempFile.getAbsolutePath()));
            getCommonPage().pushFile(fileName, tempFile.getAbsolutePath());
        } else {
            // FIXME: This does not work yet b/c appium does not find the file on the device via the name
            log.info("File named %s already found on device. Not pushing another one.");
        }
    }

    /**
     * Clicks the send button on the keyboard
     *
     * @param canSkip equals to null if this step should throw an error if the button is not available for tapping
     */
    @When("^I tap (?:Commit|Return|Send|Enter) button on the keyboard( if visible)?$")
    public void ITapCommitButtonOnKeyboard(String canSkip) {
        try {
            getCommonPage().tapKeyboardCommitButton();
        } catch (IllegalStateException e) {
            if (canSkip != null) {
                return;
            }
            throw e;
        }
    }

    /**
     * Minimizes/restores the App
     *
     * @param action either restore or minimize
     * Restore Wire only to be used after app has been put in background
     */
    @Given("^I (minimize|restore) Wire$")
    public void IMinimizeWire(String action) {
        switch (action.toLowerCase()) {
            case "minimize":
                getCommonPage().pressHomeButton();
                break;
            case "restore":
                getCommonPage().activateApp(Lifecycle.getBundleId());
                break;
            default:
                throw new IllegalArgumentException(String.format("Unknown action keyword: '%s'", action));
        }
    }

    /**
     * Verify visibility of default Map application
     */
    @Then("^I see map application is opened$")
    public void VerifyMapDefaultApplicationVisibility() {
        assertThat("The default map application is not visible",
                getCommonPage().isDefaultMapApplicationVisible());
    }

    /**
     * Set the content of clipboard content from an existing file or a string
     *
     * @param source either 'string' or 'file'
     * @param data   the name of existing text file located in tools/ios/misc/ folder
     *               The text in the file is expected to be encoded in UTF-8
     *               OR
     *               any non-empty string
     */
    @Given("^I load clipboard content from (file|string) \"(.*)\"$")
    public void ISetClipboard(String source, String data) throws IOException {
        String text = data;
        if (source.equalsIgnoreCase("file")) {
            final File srcPath = new File(String.format("%s/%s",
                    Config.current().getMiscResourcesPath(getClass()), data));
            text = new String(Files.readAllBytes(srcPath.toPath()), StandardCharsets.UTF_8);
        }
        getCommonPage().setClipboard(text);
    }

    /**
     * Set the content of clipboard content from an existing file or a string
     *
     * @param source 'okta|active directory|ldap'
     */
    @Given("^I load clipboard content with sso code from (okta)$")
    public void ISetClipboardWithSSOCode(String source) {
        String text;
        if (source.equalsIgnoreCase("okta")) {
            text = getCommonSteps().getSSOCode();
        } else {
            throw new IllegalArgumentException(String.format("Unknown source '%s'", source));
        }
        getCommonPage().setClipboard(text);
    }

    @When("^Group admin user (.*) deletes conversation (.*)$")
    public void deleteConversation(String userToNameAlias, String dstConversationName) {
        context.getCommonSteps().userXDeletesConversation(userToNameAlias, dstConversationName);
    }

    @Given("^I open Safari with url \"(.*)\"$")
    public void IOpenSafariWithURL(String url){
        getCommonPage().activateApp(SAFARI);
        getCommonPage().openURL(url);
        //getCommonPage().tapConfirmButtonIfVisible();
    }

    @When("^I wait up until (\\d+) seconds until alert is visible$")
    public void IWaitForAlertToShow(int seconds){
        assertThat(String.format("Alert has not showed up in '%s' seconds", seconds),
                getCommonPage().waitUntilAlertIsVisible(seconds));
    }

    @When("^I open deep link for conversation (.*) that user (.*) has sent me in safari$")
    public void iOpenDeepLinkForConversation(String conversationName, String nameAlias) {
        String deeplink = getCommonSteps().getDeepLinkForConversation(conversationName, nameAlias);
        getCommonPage().activateApp(SAFARI);
        getCommonPage().openURL(deeplink);
    }

    @When("^I open deep link for profile of user (.*) in safari")
    public void iOpenDeepLinkForConversation(String nameAlias) {
        String deeplink = getCommonSteps().getDeepLinkForUserProfile(nameAlias);
        getCommonPage().openDeepLink(deeplink, SAFARI);
    }

    // region legal hold

    @When("^User (.*) (un)?registers legal hold service with team \"(.*)\"$")
    public void legalHoldFeatureIsTurnedOnForTeam(String userAlias, String unregister, String teamName) {
        if(unregister == null) {
            context.getCommonSteps().registerLegalHoldService(userAlias, teamName);
        } else {
            context.getCommonSteps().unregisterLegalHoldService(userAlias, teamName);
        }
    }

    @When("^Admin user (.*) sends Legal Hold request for user (.*)$")
    public void adminUserXSendsLegalHoldRequest(String adminUserNameAlias, String userNameAlias) {
        context.getCommonSteps().adminSendsLegalHoldRequestForUser(adminUserNameAlias, userNameAlias);
    }

    @When("^Admin user (.*) turns off Legal Hold for user (.*)$")
    public void adminUserXTurnsOffLegalHold(String adminUserNameAlias, String userNameAlias) {
        context.getCommonSteps().adminTurnsOffLegalHoldForUser(adminUserNameAlias, userNameAlias);
    }

    // end region legal hold

    // region custom backend

    //TODO: Once the app with the new protocol handler becomes old, this step can be removed
    @When("^I open default backend via deep link with the old protocol in safari$")
    public void iOpenDeepLinkWithOldProtocolForDefaultBackend() {
        Backend backend = BackendConnections.getDefault();
        String protocolHandler = "wire";

        if (backend.getBackendName().contains("column-1")) {
            protocolHandler = "wire-bk";
        }

        String deeplink = backend.getDeeplinkForiOS(protocolHandler);
        log.fine("deeplink: " + deeplink);
        getCommonPage().activateApp(SAFARI);
        getCommonPage().openURL(deeplink);
    }

    @When("^I open default backend via deep link in safari$")
    public void iOpenDeepLinkForDefaultBackend() {
        getCommonPage().openDeepLinkForDefault();
    }

    @When("^I open a backend which has my build blacklisted via deep link in safari$")
    public void iOpenDeepLinkForBlacklistedBackend() {
        String deeplink = "wire://access/?config=https://wire-taco-test.s3.eu-west-1.amazonaws.com/blacklist-current.json";
        getCommonPage().openDeepLink(deeplink, SAFARI);
    }

    @When("^I open a backend which has a higher minimum version via deep link in safari$")
    public void iOpenDeepLinkForHigherMinimumBackend() {
        String deeplink = "wire://access/?config=https://wire-taco-test.s3.eu-west-1.amazonaws.com/blacklist-minimum.json";
        getCommonPage().openDeepLink(deeplink, SAFARI);
    }

    @When("^I open (.*) backend deep link in safari$")
    public void iOpenDeepLinkForCustomBackend(String backendType) {
        Backend backend = BackendConnections.getDefault();
        String protocolHandler = "wire";

        if (backend.getBackendName().contains("column")) {
            protocolHandler = backend.getBackendName().contains("column-1") ? "wire-bk-test" : "wire-c3-test";
        }

        String deeplink = BackendConnections.get(backendType).getDeeplinkForiOS(protocolHandler);
        log.info("deeplink: " + deeplink);
        getCommonPage().activateApp(SAFARI);
        getCommonPage().openURL(deeplink);
    }

    @When("^I open invite link url for conversation (.*) created by user (.*) in safari$")
    public void iOpenInviteURL(String conversationName, String userName) {
        String inviteLink = getCommonSteps().getInviteLinkOfConversation(userName, conversationName);
        getCommonPage().activateApp(SAFARI);
        getCommonPage().openURL(inviteLink);
    }

    // endregion custom backend

    // region Folders

    @When("^User (.*) adds conversation \"(.*)\" to Favorites$")
    public void userXAddsConversationToFavorites(String userNameAlias, String conversationName) {
        context.getCommonSteps().userXAddsConversationToFavorites(userNameAlias, conversationName);
    }

    @When("^User (.*) adds conversation \"(.*)\" to (.*) folder$")
    public void userXAddsConversationToFolder(String userNameAlias, String conversationName, String folder) {
        context.getCommonSteps().userXAddsConversationToFolder(userNameAlias, conversationName, folder);
    }

    // endregion Folders

    // region Build feature flags

    @Given("^SFT calling is enabled for backend$")
    public void isSFTEnabled() {
        if (!BackendConnections.getDefault().isFeatureSFTEnabled()) {
            throw new SkipException("Skip test because backend has SFT disabled");
        }
    }

    // endregion

    @When("^User (.*) disables File Sharing for team (.*)$")
    public void userOwnerDisablesFileSharingForTeam(String adminUserAlias, String teamName) {
        context.getCommonSteps().disableFileSharingFeature(adminUserAlias, teamName);
    }

    @Given("^I enable Federation$")
    public void iEnableFederation() {
        context.enableFederation();
    }

    @Given("^I enable API versioning (\\d+)$")
    public void iEnableApiVersion(int version) {
        context.enableApiVersioning(version);
    }

    @Given("^I enable MLS support$")
    public void iEnableMLSSupport() {
        context.enableMLSSupport();
    }

    @When("I reset Wire")
    public void iResetWire() {
        context.getDriver().removeApp(Lifecycle.getBundleId());
        context.getDriver().installApp(Lifecycle.getAppPath());
    }
}
