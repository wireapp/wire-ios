package com.wearezeta.auto.ios.common;

import com.google.common.collect.ImmutableMap;
import com.wearezeta.auto.common.Config;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.usrmgmt.ClientUser;

import java.time.Duration;
import java.util.logging.Logger;

import io.appium.java_client.ios.IOSDriver;
import org.json.JSONObject;
import org.openqa.selenium.Capabilities;
import org.openqa.selenium.MutableCapabilities;
import org.openqa.selenium.ScreenOrientation;
import org.openqa.selenium.WebDriver;

import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.function.Consumer;

public class IOSDriverBuilder {

    private static final Logger log = ZetaLogger.getLog(IOSDriverBuilder.class.getSimpleName());

    private URL hubUrl = null;
    private Capabilities capabilities = null;
    private MutableCapabilities extraCapabilities = new MutableCapabilities();
    private List<String> processArgs = new ArrayList<>();
    private Consumer<String> logListenerHandler = null;
    private Boolean fullReset = false;
    private Boolean allowLocation = true;
    private Boolean allowTouchID = true;
    private Boolean allowMicrophoneAccess = false;
    private Boolean allowCameraAccess = false;
    private Boolean allowAccessToAllPhotos = false;
    private Boolean allowNotifications = false;
    private Boolean uninstallAllOtherVersions = false;
    private static final String[] bundleIDs = {
        "com.wearezeta.zclient.development",
        "com.wearezeta.zclient.rc",
        "com.wearezeta.zclient.ios-release",
        "com.wearezeta.zclient.ios.beta"
    };

    public IOSDriverBuilder withCapabilities(Capabilities capabilities) {
        this.capabilities = capabilities;
        return this;
    }

    public IOSDriverBuilder withProcessArgs(String... args) {
        for (String arg : args) {
            processArgs.add(arg);
        }
        return this;
    }

    public IOSDriverBuilder withHub(URL url) {
        this.hubUrl = url;
        return this;
    }

    public IOSDriverBuilder withFastLoginUser(ClientUser fastLoginUser) {
        if (fastLoginUser != null) {
            processArgs.addAll(Arrays.asList(
                    // https://wearezeta.atlassian.net/browse/ZIOS-6747
                    "--loginemail=" + fastLoginUser.getEmail(),
                    "--loginpassword=" + fastLoginUser.getPassword()
            ));
        }
        return this;
    }

    public IOSDriverBuilder withLogListener(Consumer<String> logListenerHandler) {
        this.logListenerHandler = logListenerHandler;
        return this;
    }

    public IOSDriverBuilder withFullReset(boolean fullReset) {
        this.fullReset = fullReset;
        return this;
    }

    public void withMicrophoneAccess() {
        allowMicrophoneAccess = true;
    }

    public void withCameraAccess() {
        allowCameraAccess = true;
    }

    public void withAccessToAllPhotos() {
        allowAccessToAllPhotos = true;
    }

    public void withNotifications() {
        allowNotifications = true;
    }

    public void withUninstallingAllVersionsOfWire() {
        uninstallAllOtherVersions = true;
    }

    public WebDriver build() {
        if (hubUrl == null) {
            throw new RuntimeException("No hub url specified.");
        }

        if (capabilities == null) {
            throw new RuntimeException("No capabilities specified.");
        }

        if (!processArgs.contains("-BackendEnvironmentTypeOverrideKey")) {
            String backendType = Config.current().getBackendType(this.getClass());
            processArgs.add("-BackendEnvironmentTypeOverrideKey");
            if (backendType.equals("qa-column-1")) {
                // Using staging here because qa-column-1 is configured in the backend bundle for staging
                // See: https://github.com/wireapp/wire-ios-build-assets/blob/master/BK-CI-configuration/AppStore/Backend.bundle/staging.json
                processArgs.add("staging");
            } else if (backendType.equals("qa-column-3")) {
                // See: https://github.com/wireapp/wire-ios-build-assets/blob/master/COLUMN3-CI-configuration/RC/Backend.bundle/staging.json
                processArgs.add("staging");
            } else {
                processArgs.add(backendType);
            }
        }

        // TODO: Find a better way for adding this capability
        final JSONObject processArguments = new JSONObject();
        processArguments.put("args", processArgs);
        // Enable logging for AVS and calling modules by default
        processArguments.put("env", ImmutableMap.of("ZMLOG_TAGS", "AVS,calling"));
        extraCapabilities.setCapability("appium:processArguments", processArguments.toString());

        if (fullReset) {
            // Set full reset option (app is uninstalled) if needed
            extraCapabilities.setCapability("appium:fullReset", true);
            // Uninstall app before and after test on real device / Destroy Simulator before and after test
            // (this needs to be set because after step is skipped if resetOnSessionStartOnly = true)
            extraCapabilities.setCapability("appium:resetOnSessionStartOnly", false);
        } else {
            // reset app but leave simulator running (might not work. see https://github.com/appium/appium/issues/18814)
            extraCapabilities.setCapability("appium:noReset", false);
            extraCapabilities.setCapability("appium:fullReset", false);
            extraCapabilities.setCapability("appium:resetOnSessionStartOnly", true);
        }

        JSONObject permissions = new JSONObject();

        if (allowLocation) {
            permissions.put("location", "yes");
        }

        if (allowMicrophoneAccess) {
            permissions.put("microphone", "yes");
        }

        if (allowCameraAccess) {
            permissions.put("camera", "yes");
        }

        if (allowAccessToAllPhotos) {
            permissions.put("photos", "yes");
        }

        if (allowNotifications) {
            permissions.put("notifications", "yes");
        }

        if (allowTouchID) {
            permissions.put("faceid", "yes");
        }

        // Use applesimutils for controlling permissions
        // See https://github.com/wix/AppleSimulatorUtils#usage for permission names
        if (allowLocation || allowMicrophoneAccess || allowCameraAccess || allowAccessToAllPhotos || allowNotifications) {
            JSONObject bundles = new JSONObject();
            bundles.put(Lifecycle.getBundleId(), permissions);
            extraCapabilities.setCapability("appium:permissions", bundles.toString());
        }

        // merge all extra capabilites into the capabilites
        capabilities.merge(extraCapabilities);

        log.info(String.format("Creating webdriver with capabilities: %s", capabilities));

        final IOSDriver iosDriver = new IOSDriver(hubUrl, capabilities);

        iosDriver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
        iosDriver.setClipboardText("wire");

        if (uninstallAllOtherVersions) {
            log.info("Remove all version except with bundle id " + Lifecycle.getBundleId());
            for (String bundleID : bundleIDs) {
                if (!bundleID.equals(Lifecycle.getBundleId())) {
                    iosDriver.removeApp(bundleID);
                }
            }
        }

        //start iPad testcases in Landscape by default
        if (Config.current().isTablet(getClass())) {
            (iosDriver).rotate(
                    ScreenOrientation.LANDSCAPE);
        }

        String udid = iosDriver.getSessionId().toString();
        log.info("sessionDetail: " + udid);

        return iosDriver;
    }

}