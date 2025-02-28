package com.wearezeta.auto.ios.common;

import com.wearezeta.auto.common.Config;
import com.wearezeta.auto.common.Platform;
import com.wearezeta.auto.common.TestScreenshotHelper;
import com.wearezeta.auto.common.calling2.v1.UiCallingStatTracker;
import com.wearezeta.auto.common.driver.AppiumLocalServer;
import com.wearezeta.auto.common.log.LogListener;
import com.wearezeta.auto.common.log.LogsConverter;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.misc.WireBlacklist;
import com.wearezeta.auto.common.testiny.ScenarioResultToTestinyTransformer;
import com.wearezeta.auto.common.testiny.TestinySync;
import com.wearezeta.auto.ios.pages.IOSPage;
import com.wire.qa.picklejar.engine.TestContext;
import com.wire.qa.picklejar.engine.annotations.AfterEachScenario;
import com.wire.qa.picklejar.engine.annotations.AfterEachStep;
import com.wire.qa.picklejar.engine.annotations.BeforeEachScenario;
import com.wire.qa.picklejar.engine.annotations.BeforeEachStep;
import com.wire.qa.picklejar.engine.gherkin.model.Embeddings;
import com.wire.qa.picklejar.engine.gherkin.model.Scenario;
import com.wire.qa.picklejar.engine.gherkin.model.Step;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.logging.LogEntry;
import org.openqa.selenium.remote.DesiredCapabilities;

import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.time.Duration;
import java.util.*;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import static com.wearezeta.auto.common.CommonUtils.isRunningOnJenkinsNode;

public class Lifecycle {

    private static final Duration DEFAULT_COMMAND_TIMEOUT = Duration.ofMinutes(10);

    private static Logger log = ZetaLogger.getLog(Lifecycle.class.getSimpleName());

    private static final String TAG_NAME_BLACKLIST = "@blacklist";
    private static final String SSO = "@sso";
    private static final String SCIM = "@scim";

    private static final Platform CURRENT_PLATFORM = Platform.iOS;

    private final TestScreenshotHelper screenshotHelper = new TestScreenshotHelper();

    private static final int MAX_SCREENSHOT_WIDTH = 800;
    private static final int MAX_SCREENSHOT_HEIGHT = 400;

    private static boolean isOnGrid() {
        return Config.current().isOnGrid(Lifecycle.class);
    }

    private static String getUrl() {
        return Config.current().getAppiumUrl(Lifecycle.class);
    }

    public static String getAppPath() {
        return Config.current().getIosApplicationPath(Lifecycle.class);
    }

    public static String getOldAppPath() {
        return Config.current().getOldAppPath(Lifecycle.class);
    }

    public static String getBundleId() {
        if (isRunningOnJenkinsNode() && isOnGrid()) {
            return Config.current().getBundleId(Lifecycle.class);
        } else {
            return new IPAInspector(getAppPath()).getBundleId();
        }
    }

    private static String getAppName() {
        return Config.current().getIOSAppName(Lifecycle.class);
    }

    @BeforeEachScenario
    public TestContext setup(Scenario scenario) throws Exception {

        IOSDriverBuilder driverBuilder = new IOSDriverBuilder();

        boolean useSpecialEmail = false;

        if (scenario.hasTag("useSpecialEmail")) {
            useSpecialEmail = true;
        }

        // The appPath is the path to the ipa on the node where the simulator runs
        String appPath = getAppPath();

        // Start appium server if this test is run manually and appium not already running (for e.g. via appium-desktop)
        if (!isOnGrid() && !AppiumLocalServer.isRunning()) {
            AppiumLocalServer.start();
        }

        // TODO: Can be removed once we migrated to the new grid
        if (isRunningOnJenkinsNode() && !isOnGrid()) {
            // Add hostname to scenario description (yellow line)
            InetAddress ip = InetAddress.getLocalHost();
            String hostname = ip.getHostName();
            scenario.setDescription(hostname + ": ");
        }

        final boolean isRealDevice = !Config.current().isSimulator(getClass());

        final DesiredCapabilities capabilities = new DesiredCapabilities();
        capabilities.setCapability("newCommandTimeout", DEFAULT_COMMAND_TIMEOUT.getSeconds());
        capabilities.setCapability("app", appPath);
        // Only set the platformVersion if you have multiple sim runtimes installed
        //capabilities.setCapability("appium:platformVersion", getPlatformVersion());

        String bundleId = getBundleId();
        log.info("bundleId: " + bundleId);
        capabilities.setCapability("appium:automationName", "XCUITest");
        capabilities.setCapability("appium:bundleId", bundleId);
        capabilities.setCapability("appium:autoLaunch", true);
        capabilities.setCapability("appium:clearSystemFiles", true);
        capabilities.setCapability("appium:appName", getAppName());
        capabilities.setCapability("appium:language", "en");
        capabilities.setCapability("appium:locale", "en_US");

        //  Increase the default timeout to start up a simulator from 120s to 240s
        capabilities.setCapability("appium:simulatorStartupTimeout", 240000);

        //Temporary enable full XCode Log
        capabilities.setCapability("appium:showXcodeLog", true);

        if (!isOnGrid()) {
            // If deviceName is set appium tries to match the first available simulator/device with the given name
            capabilities.setCapability("deviceName",
                    Config.current().getDeviceName(this.getClass()));
        }

        if (isRealDevice && !isOnGrid()) {
            capabilities.setCapability("appium:udid", RealDevice.getUDID());
        }

        // Disable update notifications from Hockey
        driverBuilder.withProcessArgs("-use-app-center", "0");

        driverBuilder.withProcessArgs("--disable-interactive-keyboard-dismissal");

        driverBuilder.withProcessArgs("--disable-call-quality-survey");

        driverBuilder.withProcessArgs("--persist-backend-type");

        // https://wearezeta.atlassian.net/browse/ZIOS-5769
        driverBuilder.withProcessArgs("--disable-autocorrection");

        driverBuilder.withProcessArgs("--debug-log=Network,SessionManager,event-processing,SyncStatus,OperationStatus,"
                + "Push,cryptobox,background-activity,ephemeral,Authentication");

        driverBuilder.withProcessArgs("-com.apple.CoreData.ConcurrencyDebug", "1");

        if (!scenario.hasTag("@notifications")) {
            driverBuilder.withProcessArgs("--disable-push-alert");
        }

        driverBuilder.withProcessArgs("-UseAnalytics", "0");

        String url = getUrl();
        log.info("URL: " + url);

        final URL serverAddress;
        try {
            serverAddress = new URL(url);
        } catch (MalformedURLException e) {
            throw new IllegalStateException(e);
        }

        driverBuilder.withHub(serverAddress);

        driverBuilder.withCapabilities(capabilities);

        final LogListener logListener = new LogListener();
        driverBuilder.withLogListener(logListener::addLogMessage);

        IOSTestContext context = new IOSTestContext(scenario, useSpecialEmail, driverBuilder);
        context.setLogListener(logListener);
        return context;
    }

    @BeforeEachStep
    public void beforeEachStep(IOSTestContext context, Scenario scenario, Step step) {

    }

    @AfterEachStep
    public void afterEachStep(IOSTestContext context, Scenario scenario, Step step) {
        // Make screenshot
        try {
            if (context.isDriverCreated() && !"SKIPPED".equalsIgnoreCase(step.getResult().getStatus())) {
                byte[] screenshot = context.getDriver().getScreenshotAs(OutputType.BYTES);
                // Jenkins 1: screenshotHelper.saveScreenshot(step, scenario, scenario.getCurrentFeatureName(), screenshot);
                Embeddings embedding = new Embeddings(screenshotHelper.encodeToBase64(screenshot, MAX_SCREENSHOT_WIDTH, MAX_SCREENSHOT_HEIGHT), "image/jpeg");
                step.addEmbedding(embedding);
            }
        } catch (Exception e) {
            log.warning("Could not make a screenshot: " + e.getMessage());
        }

        // Attach logs
        try {
            if (context.isDriverCreated() && step.getResult().getErrorMessage() != null && !step.getResult().getErrorMessage().isEmpty()) {

                log.info("Get logs...");

                IOSPage page = context.getPagesCollection().getPage(IOSPage.class);

                final Map<String, List<String>> attachmentLogsData = new LinkedHashMap<>();
                final List<String> applicationLogs = page.getWireLogs();
                final List<String> deviceLogs = context.getLogListener()
                        .map(LogListener::getLogs)
                        .orElse(Collections.emptyList());
                final List<String> crashLogs = page.getCrashLogs().getAll()
                        .stream()
                        .map(LogEntry::getMessage)
                        .collect(Collectors.toList());
                final List<String> serverLogs = page.getAppiumLogs().getAll()
                        .stream()
                        .map(LogEntry::getMessage)
                        .collect(Collectors.toList());
                attachmentLogsData.put("crash.log", crashLogs);
                attachmentLogsData.put("appium.log", serverLogs);
                attachmentLogsData.put("system.txt", deviceLogs);
                attachmentLogsData.put("application.txt", applicationLogs);

                if (context.isCallingTrackerEnabled()) {
                    UiCallingStatTracker tracker = context.getUiCallingStatTracker();
                    attachmentLogsData.put("callingStats.log", tracker.getSummary());
                }

                if (!attachmentLogsData.isEmpty()) {
                    Embeddings embedding = new Embeddings(
                            LogsConverter.toZipBytearray(attachmentLogsData),
                            LogsConverter.ZIP_MIME_TYPE);
                    step.addEmbedding(embedding);
                }
            }
        } catch (Exception e) {
            log.warning("Could not attach logs: " + e.getMessage());
        }
    }

    @AfterEachScenario
    public void tearDown(IOSTestContext context, Scenario scenario) {
        try {
            TestinySync.syncExecutedScenarioWithTestiny(scenario.getName(),
                    new ScenarioResultToTestinyTransformer(scenario).transform(),
                    scenario.getTags());
        } catch (Exception e) {
            log.warning(e.getMessage());
        }

        try {
            if (context != null && context.isDriverCreated()) {
                if (context.isRealDevice()) {
                    context.getDriver().switchTo().alert().accept();
                } else {
                    context.getPagesCollection().getPage(IOSPage.class).acceptAlert(Timedelta.ofSeconds(1));
                }
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }

        if (scenario.hasTag(SSO) || scenario.hasTag(SCIM)) {
            try {
                if (context != null && context.isDriverCreated()) {
                    context.getPagesCollection().getPage(IOSPage.class).setClipboard(" ");
                }
            } catch (Exception e) {
                log.warning("Could not empty clipboard: " + e.getMessage());
            }
        }

        try {
            if (!scenario.hasTag("maintenance")) {
                log.fine("Delete application in okta");
                context.getCommonSteps().cleanUpOkta();
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            if (scenario.hasTag(TAG_NAME_BLACKLIST)) {
                WireBlacklist.uploadDefault(CURRENT_PLATFORM);
            }
            if (scenario.hasTag("notifications")) {
                if (context != null && context.isDriverCreated()) {
                    context.getPagesCollection().getPage(IOSPage.class).pressHomeButton();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        // Driver
        try {
            log.fine("Closing webdriver");
            if (context != null && context.isDriverCreated()) {
                context.getDriver().quit();
            }
        } catch (Exception e) {
            log.warning("Closing webdriver failed: " + e.getMessage());
            e.printStackTrace();
        }
        // Federation
        try {
            for (String fromBackend: context.getCommonSteps().defederatedBackends.keySet()) {
                log.info("Repair defederation");
                context.getCommonSteps().federateBackends(fromBackend,
                        context.getCommonSteps().defederatedBackends.get(fromBackend));
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            for (String backendName: context.getCommonSteps().touchedFederator) {
                log.info("Turn federator back on");
                context.getCommonSteps().turnFederatorInBackendOn(backendName);
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            for (String backendName: context.getCommonSteps().touchedBrig) {
                log.info("Turn brig back on");
                context.getCommonSteps().turnBrigInBackendOn(backendName);
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            for (String backendName: context.getCommonSteps().touchedGalley) {
                log.info("Turn galley back on");
                context.getCommonSteps().turnGalleyInBackendOn(backendName);
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            for (String backendName: context.getCommonSteps().touchedIngress) {
                log.info("Turn ingress back on");
                context.getCommonSteps().turnIngressInBackendOn(backendName);
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            for (String backendName: context.getCommonSteps().touchedSFT) {
                log.info("Turn SFT back on");
                context.getCommonSteps().turnSFTInBackendOn(backendName);
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        // Local appium
        try {
            if (!isOnGrid()) {
                log.fine("Stopping appium");
                AppiumLocalServer.stop();
            }
        } catch (Exception e) {
            log.warning("Stopping appium failed: " + e.getMessage());
        }

        try {
            if (!isOnGrid()) {
                // TODO: This breaks parallel runs and ends in a loop
                context.printCallingStatsIfEnabled();
            }
            if (context != null) {
                context.reset();
            }
        } catch (Exception e) {
            log.severe("Could not reset context: " + e.getMessage());
        }

        try {
            log.fine("Releasing Testservice instances");
            context.getCommonSteps().cleanUpTestServiceInstances();
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            log.fine("Cleaning up calling instances");
            context.getCallingManager().cleanup();
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        try {
            if (!scenario.hasTag("maintenance")) {
                log.fine("Cleanup backends");
                context.getCommonSteps().cleanUpBackends();
            }
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
    }

}