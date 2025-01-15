package com.wearezeta.auto.ios.common;

import com.wearezeta.auto.common.*;
import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.calling2.v1.UiCallingStatTracker;
import com.wearezeta.auto.common.log.LogListener;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wire.qa.picklejar.engine.gherkin.model.Scenario;
import io.appium.java_client.ios.IOSDriver;
import org.json.JSONObject;
import org.openqa.selenium.WebDriver;

import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.Future;
import java.util.function.Supplier;
import java.util.logging.Logger;

public class IOSTestContext extends CommonTestContext {

    private static final Logger log = ZetaLogger.getLog(IOSTestContext.class.getSimpleName());

    private final String testname;
    private static final String CALLING_STATS = "@call_stats";
    public static final Timedelta NO_EXPIRATION = Timedelta.ofSeconds(0);
    private final IOSDriverBuilder driverBuilder;

    private WebDriver driver;
    private PagesCollection pagesCollection = null;
    private final Pinger pinger;

    private LogListener deviceLogListener;
    private UiCallingStatTracker uiCallingStatTracker;
    private final Scenario scenario;
    private final Map<ClientUser, Map<String, Timedelta>> EPHEMERAL_TIMEOUTS_MAP = new HashMap<>();
    private List<BufferedImage> additionalScreenshots = new ArrayList<>();

    // remember states
    private ElementState likeIconState = null;
    private ElementState profilePictureState = null;
    private ElementState colorPickerState = null;
    private String currentDeviceId = null;
    private Future<String> activationMessage = null;
    private Future<String> verificationMessage = null;
    private Future<String> accountRemovalConfirmation;
    private ClientUser userToRegister = null;
    private String rememberedCertificate = null;

    public IOSTestContext(Scenario scenario, boolean useSpecialEmail, IOSDriverBuilder driverBuilder) {
        super(useSpecialEmail);
        this.uiCallingStatTracker = new UiCallingStatTracker();
        this.scenario = scenario;
        this.pinger = new Pinger(this);
        this.testname = scenario.getName();
        this.driverBuilder = driverBuilder;
    }

    public IOSDriver getDriver() {
        if (!isDriverCreated()) {
            log.info("Driver is not created yet. Using driver builder...");
            this.driver = driverBuilder.build();
        }
        return (IOSDriver) this.driver;
    }

    public boolean isDriverCreated() {
        return driver != null;
    }

    public void doFullReset() {
        if (!isDriverCreated()) {
            driverBuilder.withFullReset(true);
        } else {
            throw new RuntimeException("Driver was already created. Cannot add capabilities anymore.");
        }
    }

    public void startAppOnProductionBackend() {
        if (!isDriverCreated()) {
            driverBuilder.withProcessArgs("-BackendEnvironmentTypeOverrideKey", "production");
            log.info("Starting app on Production backend");
        } else {
            throw new RuntimeException("Driver was already created. Cannot add capabilities anymore.");
        }
    }

    public void uninstallAllVersionsOfWire() {
        if (!isDriverCreated()) {
            driverBuilder.withUninstallingAllVersionsOfWire();
        } else {
            throw new RuntimeException("Cannot uninstall other versions of Wire after driver was created.");
        }
    }

    public void enrollSimulatorTouchID() {
        getDriver().toggleTouchIDEnrollment(true);
    }

    public void setFastLoginUser(ClientUser fastLoginUser) {
        if (!isDriverCreated()) {
            driverBuilder.withFastLoginUser(fastLoginUser);
        } else {
            throw new RuntimeException("Driver was already created. Cannot add capabilities anymore.");
        }
    }

    public void allowMicrophoneAccess() {
        if (!isDriverCreated()) {
            driverBuilder.withMicrophoneAccess();
        } else {
            throw new RuntimeException("Cannot allow permissions after driver was created.");
        }
    }

    public void allowCameraAccess() {
        if (!isDriverCreated()) {
            driverBuilder.withCameraAccess();
        } else {
            throw new RuntimeException("Cannot allow permissions after driver was created.");
        }
    }

    public void allowAccessToAllPhotos() {
        if (!isDriverCreated()) {
            driverBuilder.withAccessToAllPhotos();
        } else {
            throw new RuntimeException("Cannot allow permissions after driver was created.");
        }
    }

    public PagesCollection getPagesCollection() {
        if (pagesCollection == null) {
            log.info("Pages collection not initialized yet...");
            try {
                // The driver needs to be finally initialized here so that the method isDriverCreated() works in the context
                getDriver();
            } catch (Exception e) {
                log.severe("Driver initialization failed");
                throw new RuntimeException("Driver initialization failed: " + e.getMessage(), e);
            }
            pagesCollection = new PagesCollection(this.driver);
        }
        return pagesCollection;
    }

    public void reset() {
        // noop
    }

    public void startPinging() {
        if(isDriverCreated()) {
            pinger.startPinging();
        }
    }

    public void stopPinging() {
        if(isDriverCreated()) {
            pinger.stopPinging();
        }
    }

    /**
     * From MobileTestContext
     */

    public boolean isRealDevice() {
        return !Config.current().isSimulator(getClass());
    }

    public Scenario getScenario() {
        return scenario;
    }

    public Optional<LogListener> getLogListener() {
        return Optional.ofNullable(deviceLogListener);
    }

    public void setLogListener(LogListener logListener) {
        this.deviceLogListener = logListener;
    }

    public UiCallingStatTracker getUiCallingStatTracker() {
        return uiCallingStatTracker;
    }

    public boolean isCallingTrackerEnabled() {
        return  scenario.hasTag(CALLING_STATS);
    }

    public void printCallingStatsIfEnabled() {
        try {
            if (isCallingTrackerEnabled()) {
                UiCallingStatTracker tracker = getUiCallingStatTracker();
                log.info(String.join("\n", tracker.getSummary()));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public Timedelta getSelfDeletingMessageTimeout(String userAlias, String conversationName) {
        final ClientUser user = getUsersManager().findUserByNameOrNameAlias(userAlias);

        // only team users support enforced self-deleting messages
        if (user.getTeamId() != null) {
            JSONObject selfDeletingMessagesSettings = BackendConnections.get(user).getSelfDeletingMessagesSettings(user);

            if (selfDeletingMessagesSettings.getString("status").equals("enabled")) {
                int timeoutInSeconds = selfDeletingMessagesSettings.getJSONObject("config").getInt("enforcedTimeoutSeconds");
                if (timeoutInSeconds != 0) {
                    // timeout value is enforced in team settings
                    return Timedelta.ofSeconds(timeoutInSeconds);
                }
            } else {
                // timeout is disabled
                return NO_EXPIRATION;
            }
        }

        // Personal user or team user without set enforced self-deleting message setting

        // follow conversation settings if there is any
        conversationName = getUsersManager().replaceAliasesOccurrences(conversationName,
                ClientUsersManager.FindBy.NAME_ALIAS);
        int conversationMessageTimer = getCommonSteps().getConversationMessageTimer(user, conversationName);
        if (conversationMessageTimer > 0) {
            return Timedelta.ofMillis(conversationMessageTimer);
        }

        // otherwise check for local/client-side self-deleting message timeout
        return getLocalSelfDeletingMessageTimeout(userAlias, conversationName);
    }

    private Timedelta getLocalSelfDeletingMessageTimeout(String userAlias, String conversationName) {
        final ClientUser user = getUsersManager().findUserByNameOrNameAlias(userAlias);
        conversationName = getUsersManager().replaceAliasesOccurrences(conversationName,
                ClientUsersManager.FindBy.NAME_ALIAS);
        final String conversationId = BackendConnections.get(user).getConversationByName(user, conversationName).getId();
        if (EPHEMERAL_TIMEOUTS_MAP.containsKey(user) && EPHEMERAL_TIMEOUTS_MAP.get(user).containsKey(conversationId)) {
            return EPHEMERAL_TIMEOUTS_MAP.get(user).get(conversationId);
        }
        return NO_EXPIRATION;
    }

    /**
     * From TestContext
     */

    public void addAdditionalScreenshots(BufferedImage screenshot) {
        additionalScreenshots.add(screenshot);
    }

    public void enableFederation() {
        if (!isDriverCreated()) {
            driverBuilder.withProcessArgs("-FederationEnabled", "1");
            log.info("Starting app with Federation enabled");
        } else {
            throw new RuntimeException("Driver was already created. Cannot add federation enabled capabilities anymore.");
        }
    }

    public void enableApiVersioning(int version) {
        if (!isDriverCreated()) {
            driverBuilder.withProcessArgs(String.format("--preferred-api-version=%s", version));
            log.info(String.format("Starting app with Api versioning %s enabled", version));
        } else {
            throw new RuntimeException("Driver was already created. Cannot add federation enabled capabilities anymore.");
        }
    }

    public void enableMLSSupport() {
        if (!isDriverCreated()) {
            driverBuilder.withProcessArgs("--enable-mls-support", "1");
            log.info("Starting app with mls support enabled");
        } else {
            throw new RuntimeException("Driver was already created. Cannot add federation enabled capabilities anymore.");
        }
    }

    public ElementState getLikeIconState() {
        return likeIconState;
    }

    public void setLikeIconState(Supplier<BufferedImage> screenshotFunction) throws Exception {
        this.likeIconState = new ElementState(screenshotFunction);
        likeIconState.remember();
    }

    public ElementState getProfilePictureState() {
        return profilePictureState;
    }

    public void setProfilePictureState(Supplier<BufferedImage> screenshotFunction) throws Exception {
        this.profilePictureState = new ElementState(screenshotFunction);
        this.profilePictureState.remember();
    }

    public ElementState getColorPickerState() {
        return colorPickerState;
    }

    public void setColorPickerState(Supplier<BufferedImage> screenshotFunction) throws Exception {
        this.colorPickerState = new ElementState(screenshotFunction);
        this.colorPickerState.remember();
    }

    public String getCurrentDeviceId() {
        return this.currentDeviceId;
    }

    public void setCurrentDeviceId(String deviceId) {
        this.currentDeviceId = deviceId;
    }

    public Future<String> getActivationMessage() {
        return activationMessage;
    }

    public Future<String> getVerificationMessage() {
        return verificationMessage;
    }

    public void setActivationMessage(Future<String> message) {
        this.activationMessage = message;
    }

    public void setVerificationMessage(Future<String> message) {
        this.verificationMessage = message;
    }

    public Future<String> getAccountRemovalConfirmation() {
        return accountRemovalConfirmation;
    }

    public void setAccountRemovalConfirmation(Future<String> message) {
        this.accountRemovalConfirmation = message;
    }

    public ClientUser getUserToRegister() {
        return userToRegister;
    }

    public void setUserToRegister(ClientUser user) {
        this.userToRegister = user;
    }

    public String getRememberedCertificate() {
        return rememberedCertificate;
    }

    public void setRememberedCertificate(String remembered) {
        this.rememberedCertificate = remembered;
    }
}
