package com.wearezeta.auto.ios.pages.calling;

import com.google.zxing.NotFoundException;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.ios.IOSTouchAction;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import io.appium.java_client.touch.WaitOptions;
import io.appium.java_client.touch.offset.PointOption;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.imagecomparator.QRCode;
import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.Dimension;
import org.openqa.selenium.WebElement;
import java.awt.image.BufferedImage;
import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.function.BiFunction;
import java.util.function.Function;

public class VideoCallingOverlayPage extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "name BEGINSWITH 'videoView' AND name CONTAINS 'maximized' AND type == 'XCUIElementTypeButton'")
    private WebElement maximizedVideoView;

    public VideoCallingOverlayPage(WebDriver driver) {
        super(driver);
    }

    private static final String strNameParticipantCell = "user_cell.name";

    private static final String nameStrParticipantCamera = "img.video";

    private static String nameMicrophoneUnmuted = "Microphone on";
    private static String nameMicrophoneMuted = "Microphone off";

    @iOSXCUITFindBy(accessibility = "ThumbnailView")
    private WebElement videoSelfPreview;

    @iOSXCUITFindBy(accessibility = "Double tap to go back, pinch to zoom")
    private WebElement iSeeZoomInMessage;

    @iOSXCUITFindBy(accessibility = "Double tap on a tile for fullscreen")
    private WebElement iSeeFullScreenMessage;

    @iOSXCUITFindBy(accessibility = "speakers_and_all_toggle.selected.all")
    private WebElement speakerAndAllTabSelectedAll;

    @iOSXCUITFindBy(accessibility = "speakers_and_all_toggle.selected.speakers")
    private WebElement speakerAndAllTabSelectedSpeakers;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'SPEAKERS' AND name == 'SPEAKERS' AND type == 'XCUIElementTypeButton'")
    private WebElement speakerTab;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'ALL' AND name == 'ALL' AND value == 'ALL'")
    private WebElement allTab;

    @iOSXCUITFindBy(accessibility = "No active video speakers...")
    private WebElement noActivitySpeakerIcon;

    @iOSXCUITFindBy(iOSNsPredicate = "value CONTAINS 'page 1'")
    private WebElement firstPagePaginationIcon;

    @iOSXCUITFindBy(iOSNsPredicate = "value == 'page 2 of 7'")
    private WebElement secondPagePaginationIcon;

    @iOSXCUITFindBy(iOSNsPredicate = "value BEGINSWITH 'page'")
    private WebElement paginationIcon;

    @iOSXCUITFindBy(iOSNsPredicate = "label CONTAINS 'camera'")
    private WebElement callVideoButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label CONTAINS 'speaker'")
    private WebElement callSpeakerButton;

    @iOSXCUITFindBy(accessibility = "Turn off microphone")
    private WebElement activeMuteButton;

    @iOSXCUITFindBy(accessibility = "Turn on microphone")
    private WebElement inactiveMuteButton;

    @iOSXCUITFindBy(accessibility = "Turn on camera")
    private WebElement switchONCameraButton;

    @iOSXCUITFindBy(accessibility = "Turn off camera")
    private WebElement switchOffCameraButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Minimize calling view'")
    private WebElement minimizeButton;

    @iOSXCUITFindBy(accessibility = "toast.mutedOnJoin")
    private WebElement muteIndicatorBanner;

    @iOSXCUITFindBy(accessibility = "btn.close")
    private WebElement closeButton;

    @iOSXCUITFindBy(accessibility = "End call")
    private WebElement callLeaveButton;

    @iOSXCUITFindBy(accessibility = "ClassificationBannerClassified")
    private WebElement nameClassifiedDomainLabel;

    @iOSXCUITFindBy(accessibility = "ClassificationBannerUnclassified")
    private WebElement nameUnclassifiedDomainLabel;

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND label == 'Back'")
    private WebElement tapBackButton;

    @iOSXCUITFindBy(accessibility = "Learn more about Wire’s pricing")
    private WebElement learnMoreAboutWirePricingButton;

    @iOSXCUITFindBy(accessibility = "Upgrade now")
    private WebElement upgradeNowButton;

    @iOSXCUITFindBy(accessibility = "Learn more about the Enterprise plan")
    private WebElement learnMoreAboutWireEnterpriseButton;

    @iOSXCUITFindBy(accessibility = "CallStatusLabel")
    private WebElement nameCallStatusLabel;

    @iOSXCUITFindBy(accessibility = "Accept")
    private WebElement acceptButton;

    @iOSXCUITFindBy(accessibility = "OK")
    private WebElement okButton;

    @iOSXCUITFindBy(accessibility = "Allow")
    private WebElement allowButton;

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'New Device' AND name == 'New Device' AND value == 'New Device'")
    private WebElement alertNewDevice;

    @iOSXCUITFindBy(accessibility = "CallFlipCameraButton")
    private WebElement switchCameraButton;

    @iOSXCUITFindBy(accessibility = "ConferenceCallingBadge")
    private WebElement nameConferenceCallingBadge;

    @iOSXCUITFindBy(accessibility = "OpenOngoingCallButton")
    private WebElement nameRestoreOverlayButton;

    // Copied from AVCallingOverlayPage to remove inheritance
    private static final By nameMinimizeOverlayButton = MobileBy.AccessibilityId("CallDismissOverlayButton");
    private static final By predicateSeeAllButton = MobileBy.iOSNsPredicateString("name BEGINSWITH 'Show All'");
    private static final By nameEndCallButton = MobileBy.AccessibilityId("LeaveCallButton");
    private static final By nameSpeakersButton = MobileBy.AccessibilityId("CallSpeakerButton");
    private static final By nameMuteCallButton = MobileBy.AccessibilityId("CallMuteButton");
    protected static final By nameCallVideoButton = MobileBy.iOSNsPredicateString("label CONTAINS 'camera'");
    private static final By nameAcceptCallButton = MobileBy.AccessibilityId("AcceptButton");
    private static final By nameBitRateLabel = MobileBy.AccessibilityId("bitrate-indicator");

    private static final By predicateLoudspeakerToggled = MobileBy.iOSNsPredicateString("type == 'XCUIElementTypeButton' AND name == 'CallSpeakerButton' AND value == '1'");

    private static final Function<String, By> predicateCallingSpeakerByName = name -> MobileBy.iOSNsPredicateString(String.format("name == 'Turn on speaker' AND label CONTAINS '%s'", name));

    private static final Function<String, By> predicateCallingMuteByName = name -> MobileBy.iOSNsPredicateString(String.format("name == 'Turn off microphone' AND label CONTAINS '%s'", name));

    private static final Function<String, By> predicateCallingMessageByName = name -> MobileBy.iOSNsPredicateString(String.format("name == '%s' AND label CONTAINS '%s'", name, name));

    private static final Function<String, By> predicateActiveVideoParticipant = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("label CONTAINS '%s' AND label CONTAINS 'Camera on' AND label CONTAINS 'Microphone on' AND label CONTAINS 'Active speaker' AND type == 'XCUIElementTypeButton'", usernameAlias));

    private static final Function<String, By> predicateActiveVideoParticipantList = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("label CONTAINS '%s' AND label CONTAINS 'Microphone on' AND type == 'XCUIElementTypeStaticText'", usernameAlias));

    private static final Function<String, By> predicateMaximizedVideoView = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("name BEGINSWITH 'videoView' AND name CONTAINS '%s' AND name CONTAINS 'maximized' AND type == 'XCUIElementTypeButton'", usernameAlias));

    private static final Function<String, By> predicateMinimizedVideoView = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("name BEGINSWITH 'videoView' AND name CONTAINS '%s' AND name CONTAINS 'minimized' AND type == 'XCUIElementTypeButton'", usernameAlias));

    private static final Function<String, By> predicateActiveSpeakerVideoView = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("name BEGINSWITH 'videoView' AND name CONTAINS '%s' AND name CONTAINS 'minimized' AND name ENDSWITH 'active' AND type == 'XCUIElementTypeButton'", usernameAlias));

    private static final Function<String, By> predicateActiveSpeaker1to1VideoView = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("name BEGINSWITH 'videoView' AND name CONTAINS '%s' AND name CONTAINS 'minimized' AND name ENDSWITH 'active' AND type == 'XCUIElementTypeStaticText'", usernameAlias));

    private static final Function<String, By> predicateInActiveSpeakerVideoView = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("name BEGINSWITH 'videoView' AND name CONTAINS '%s' AND name CONTAINS 'minimized' AND name ENDSWITH 'inactive' AND type == 'XCUIElementTypeButton'", usernameAlias));

    private static final Function<String, By> predicateAvatarGroupAudioParticipant = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("label CONTAINS '%s' AND label CONTAINS 'Camera off' AND label CONTAINS 'Microphone' AND type == 'XCUIElementTypeButton'", usernameAlias));

    private static final Function<String, By> predicateAvatarAudioParticipant = usernameAlias -> MobileBy.iOSNsPredicateString(String.format("label CONTAINS '%s' AND label CONTAINS 'Camera off' AND label CONTAINS 'Microphone' AND type == 'XCUIElementTypeStaticText'", usernameAlias));

    private static final Function<String, By> nameOfParticipantOnLabel = name -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCollectionView/XCUIElementTypeCell[$name == 'GridCell'$]/XCUIElementTypeOther/XCUIElementTypeButton[$name CONTAINS[cd] '%s' OR name CONTAINS[cd] '%s (You)'$]", name, name));

    private static final BiFunction<Integer, String, By> nameOfParticipantOnLabelOnPosition = (position, name) -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCollectionView/XCUIElementTypeCell[$name == 'GridCell'$][%s]/**/XCUIElementTypeButton[$label CONTAINS[cd] '%s' OR label CONTAINS[cd] '%s (You)'$]", position, name, name));

    private static final Function<Integer, By> muteImageOnParticipantLabel = position -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCollectionView/XCUIElementTypeCell[$name == 'GridCell'$][%s]/**/XCUIElementTypeButton[$label CONTAINS[cd] '%s'$]", position, nameMicrophoneMuted));

    private static final Function<Integer, By> unmuteImageOnParticipantLabel = position -> MobileBy.iOSClassChain(
            String.format("**/XCUIElementTypeCollectionView/XCUIElementTypeCell[$name == 'GridCell'$][%s]/**/XCUIElementTypeButton[$label CONTAINS[cd] '%s'$]", position, nameMicrophoneUnmuted));

    private static final Function<Integer, By> classChainGroupCallParticipantsCellByIdx = idx ->
            MobileBy.iOSClassChain(String.format(
                    "**/XCUIElementTypeCollectionView/XCUIElementTypeStaticText/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeStaticText[$name == '%s'$][%s]",
                    strNameParticipantCell, idx));

    private static final BiFunction<String, String, By> classChainGroupCallParticipantsCellByNameAndText =
            (name, text) -> MobileBy.iOSClassChain(String.format(
                    "**/XCUIElementTypeCollectionView/XCUIElementTypeStaticText/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeStaticText[$name == '%s'$][$value CONTAINS[cd] '%s'$][$label CONTAINS[cd] '%s'$]", strNameParticipantCell, name, text));

    private static final Function<String, By> classChainGroupCallParticipantsCellByName = name ->
            MobileBy.iOSClassChain(String.format(
                    "**/XCUIElementTypeCollectionView/XCUIElementTypeStaticText[$name == '%s'$]/" +
                            "**/*[`value == '%s' OR value == '%s (You)'`]", strNameParticipantCell, name, name));

    private static final BiFunction<String, Integer, By> classChainGroupCallParticipantsCellByNameAndIdx = (name, idx) ->
            MobileBy.iOSClassChain(String.format(
                    "**/XCUIElementTypeCollectionView/XCUIElementTypeStaticText[$name == '%s'$][%s]/" +
                            "**/*[`value == '%s' OR value == '%s (You)'`]", strNameParticipantCell, idx, name, name));

    private static final BiFunction<String, String, By> classChainGroupCallParticipantsCellByNameAndIcon =
            (name, iconId) -> MobileBy.iOSClassChain(String.format(
                    "**/XCUIElementTypeCollectionView/XCUIElementTypeStaticText[$name == '%s'$][$value == '%s' OR value == '%s (You)'$]/" +
                            "**/*[`name == '%s'`]", strNameParticipantCell, name, name, iconId));

    private static final BiFunction<String, String, By> classChainGroupCallParticipantsCellByNameAndMuteIcon =
            (name, iconId) -> MobileBy.iOSClassChain(String.format(
                    "**/XCUIElementTypeCollectionView/XCUIElementTypeStaticText[`name CONTAINS[cd] '%s'`]/" +
                            "XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeImage[`name == '%s'`]", name, iconId));

    public void tapDeclineButton(){
        tapAtTheCenterOfElement(callLeaveButton);
    }

    public boolean isBitRateLabelVisible() {
        return getDriver().findElement(nameBitRateLabel).isDisplayed();
    }

    public boolean isBitRateLabelInvisible() {
        return isLocatorInvisible(nameBitRateLabel);
    }

    public boolean isMuteIndicatorBannerVisible() {
        return muteIndicatorBanner.isDisplayed();
    }

    public boolean isMuteIndicatorBannerInvisible() {
        return isElementInvisible(muteIndicatorBanner);
    }

    public void tapCloseButtonOnMuteIndicatorBanner(){
        closeButton.click();
    }

    @Deprecated // Please don't add more and instead use individual methods and iOSXCUITFindBy
    protected By getLocatorByName(final String name) {
        switch (name) {
            case "Minimize":
                return nameMinimizeOverlayButton;
            case "Mute":
                return nameMuteCallButton;
            case "Leave":
                return nameEndCallButton;
            case "Accept":
                return nameAcceptCallButton;
            case "Call Video":
                return nameCallVideoButton;
            case "Call Speaker":
                return nameSpeakersButton;
            case "Show All":
                return predicateSeeAllButton;
            case "Constant Bitrate":
            case "VARIABLE BIT RATE":
                return nameBitRateLabel;
            default:
                throw new IllegalArgumentException(String.format("Button name '%s' is unknown", name));
        }
    }

    public void iTapOnScreen() {
        tapScreenByPercents(50,50);
    }

    public boolean iSeeAvatarGroupAudioParticipants(String usernameAlias) {
        return isLocatorExist(predicateAvatarGroupAudioParticipant.apply(usernameAlias));
    }

    public boolean iDontSeeGroupAvatarAudioParticipants(String usernameAlias) {
        return isLocatorInvisible(predicateAvatarGroupAudioParticipant.apply(usernameAlias));
    }

    public boolean isCountOfParticipantsEqualTo(int expectedNumberOfParticipants, Timedelta timeout) {
        assert expectedNumberOfParticipants > 0 : "The expected number of participants should be greater than zero";
        if (expectedNumberOfParticipants < 8) {
            final By locator = classChainGroupCallParticipantsCellByIdx.apply(expectedNumberOfParticipants);
            return isLocatorExist(locator, timeout);
        } else {
            return isLocatorExist(MobileBy.AccessibilityId(String.format("PARTICIPANTS (%s)", expectedNumberOfParticipants)));
        }
    }

    public boolean isRestoreButtonVisible() {
        return waitUntilElementVisible(nameRestoreOverlayButton);
    }

    public void tapRestoreButton() {
        nameRestoreOverlayButton.click();
    }

    public void iTapMinimize(){
        minimizeButton.click();
    }

    public boolean iSeeLeaveCallButton(){
        return waitUntilElementVisible(callLeaveButton);
    }

    public boolean iDontSeeLeaveCallButton(){
        return waitUntilElementInvisible(callLeaveButton);
    }

    public boolean isClassifiedLabelVisibleOnCallingOverlay() {
        return waitUntilElementVisible(nameClassifiedDomainLabel);
    }

    public boolean isClassifiedLabelInvisibleOnCallingOverlay() {
        return waitUntilElementInvisible(nameClassifiedDomainLabel);
    }

    public boolean isUnclassifiedLabelVisibleOnCallingOverlay() {
        return waitUntilElementVisible(nameUnclassifiedDomainLabel);
    }

    public void tapActiveMuteButton() {
        activeMuteButton.click();
    }
    public void tapInactiveMuteButton() {
        inactiveMuteButton.click();
    }
    public boolean isUnclassifiedLabelInvisibleOnCallingOverlay() {
        return waitUntilElementInvisible(nameUnclassifiedDomainLabel);
    }

    public void tapBackButton(){
        tapAtTheCenterOfElement(tapBackButton);
    }

    public boolean isCallingMessageContainingVisible(String text) {
        return isLocatorDisplayed(predicateCallingMessageByName.apply(text));
    }

    public void tapAcceptButton(){
        acceptButton.click();
    }

    public void tapOKButton() {
        waitUntilElementVisible(okButton);
        okButton.click();
    }

    public void swipeUpParticipantsList(){
        Dimension dimension = getDriver().manage().window().getSize();
        int scrollStart = (int) (dimension.getHeight() * 0.9);
        int scrollEnd = (int) (dimension.getHeight() * 0.1);
        IOSTouchAction action = new IOSTouchAction(getDriver());
        action.press(PointOption.point(1,scrollStart))
                .waitAction(WaitOptions.waitOptions(Duration.ofMillis(300)))
                .moveTo(PointOption.point(1, scrollEnd))
                .release().perform();
    }

    public boolean iSeeNewDeviceAlert(){
        waitUntilElementVisible(alertNewDevice);
        return alertNewDevice.isDisplayed();
    }

    public boolean iDontSeeNewDeviceAlert(){
        return isElementInvisible(alertNewDevice);
    }
}
