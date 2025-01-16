package com.wearezeta.auto.ios.pages;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;
import java.util.stream.Collectors;

import com.google.common.collect.ImmutableMap;
import com.wearezeta.auto.common.Config;
import com.wearezeta.auto.common.ImageUtil;
import com.wearezeta.auto.common.backend.Backend;
import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.email.MailboxProvider;
import com.wearezeta.auto.common.email.handlers.ISupportsMessagesPolling;
import com.wearezeta.auto.common.email.messages.VerificationMessage;
import com.wearezeta.auto.common.email.messages.WireMessage;
import com.wearezeta.auto.common.imagecomparator.QRCode;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.common.Lifecycle;
import io.appium.java_client.AppiumBy;
import io.appium.java_client.MobileBy;
import io.appium.java_client.ios.IOSDriver;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;

import java.util.logging.Logger;

import org.openqa.selenium.*;
import com.wearezeta.auto.ios.pages.keyboard.IOSKeyboard;
import org.openqa.selenium.Dimension;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.Point;
import org.openqa.selenium.Rectangle;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.logging.LogEntries;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.remote.RemoteWebElement;
import org.openqa.selenium.support.ui.*;

import javax.annotation.Nullable;
import javax.imageio.ImageIO;

public class IOSPage {
    private static final Logger log = ZetaLogger.getLog(IOSPage.class.getSimpleName());

    @iOSXCUITFindBy(accessibility = "Allow Access to All Photos")
    private WebElement allowAccessToAllPhotosItem;

    @iOSXCUITFindBy(accessibility = "Not Now")
    private WebElement notNowButton;

    private static final String CRASHLOG = "crashlog";
    private static final String SERVER_LOG = "server";
    private static final String STRING_NOTIFICATION_ALERT = "Would Like to Send You Notifications";

    private static final int DEFAULT_RETRY_COUNT = 2;

    private static final Function<String, By> predicateAlertLabelByText = text ->
            MobileBy.iOSNsPredicateString(String.format("label CONTAINS '%s'", text));

    private static final By classAlertTitle = By.className("XCUIElementTypeAlert");

    private static final By classAlertDescription = By.xpath("//XCUIElementTypeAlert//XCUIElementTypeStaticText[2]");

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND name == 'Cancel'")
    private WebElement cancelButton;

    // Self node can only be found by xpath
    @iOSXCUITFindBy(xpath = "//XCUIElementTypeApplication[@name='Maps']")
    private WebElement mapsApplicationButton;

    private IOSKeyboard onScreenKeyboard;

    protected final WebDriver driver;

    public IOSPage(WebDriver driver) {
        this.driver = driver;
    }

    protected IOSDriver getDriver() {
        return (IOSDriver) this.driver;
    }

    private IOSKeyboard getOnScreenKeyboard() {
        if (this.onScreenKeyboard == null) {
            this.onScreenKeyboard = new IOSKeyboard(getDriver());
        }
        return this.onScreenKeyboard;
    }

    public boolean isKeyboardVisible() {
        return this.getOnScreenKeyboard().isVisible();
    }

    public boolean isKeyboardInvisible(Timedelta timeout) {
        return this.getOnScreenKeyboard().isInvisible(timeout);
    }

    public void tapHideKeyboardButton() {
        //The Appium method hideKeyboard() is known to be unstable
        // https://developers.perfectomobile.com/display/TT/iOS+Limitation%3A+Appium+hideKeyboard+Method
        //getDriver().hideKeyboard();
        this.getOnScreenKeyboard().pressHideButton();
    }

    public void tapSpaceKeyboardButton() {
        this.getOnScreenKeyboard().pressSpaceButton();
    }

    public void tapNextKeyboardButton() {
        this.getOnScreenKeyboard().pressNextButton();
    }

    public void tapKeyboardCommitButton() {
        this.getOnScreenKeyboard().pressCommitButton();
    }

    public boolean waitUntilAlertIsVisible(Duration timeout) {
        new WebDriverWait(getDriver(), timeout)
                .ignoring(NoAlertPresentException.class)
                .withMessage("No alert has been shown")
                .until(ExpectedConditions.alertIsPresent());
        return true;
    }

    public boolean waitUntilAlertIsVisible(int seconds) {
        return getElementIfDisplayed(classAlertTitle, Timedelta.ofSeconds(seconds)).isPresent();
    }

    public boolean acceptAlertIfVisible() {
        try {
            acceptAlert(Timedelta.ofSeconds(5));
            return true;
        } catch (TimeoutException e) {
            log.info(String.format("Did not accept the alert: %s", e.getMessage()));
            return false;
        }
    }

    public boolean isNotNowOnPasswordPromptVisible() {
        log.info("Password keychain shown?");
        try {
            getDriver().manage().timeouts().implicitlyWait(Duration.ZERO);
            new WebDriverWait(getDriver(), Duration.ofSeconds(2))
                    .ignoring(StaleElementReferenceException.class)
                    .until(driver -> !driver.findElements(AppiumBy.accessibilityId("Not Now")).isEmpty());
            log.info("Password keychain shown");
            return true;
        } catch (TimeoutException e) {
            log.info("Password keychain question was not shown");
            return false;
        } finally {
            getDriver().manage().timeouts().implicitlyWait(Duration.ofSeconds(getDefaultLookupTimeoutSeconds()));
        }
    }

    public void tapNotNowOnPasswordPrompt() {
            notNowButton.click();
    }

    public void acceptNotificationAlertIfVisible() {
        if (isAlertContainsText(STRING_NOTIFICATION_ALERT)) {
            acceptAlert();
        }
    }

    public void acceptAlert() {
        acceptAlert(getDefaultLookupTimeout());
    }

    public void acceptAlert(Timedelta timeout) {
        if (waitUntilAlertIsVisible(timeout.asDuration())) {
            getDriver().switchTo().alert().accept();
        } else {
            throw new TimeoutException("Alert did not appear after " + timeout.toString());
        }
    }

    public void acceptAccessToAllPhotos() {
        allowAccessToAllPhotosItem.click();
    }

    public void performTouchID(boolean match) {
        getDriver().performTouchID(match);
    }

    public void typeAlertText(String text) {
        getDriver().switchTo().alert().sendKeys(text);
    }

    private enum AlertAction {
        ACCEPT, DISMISS, TAP_BUTTON
    }

    private void handleAlert(AlertAction action, @Nullable String buttonLabel, Timedelta timeout) {
        if (action != AlertAction.TAP_BUTTON && buttonLabel != null) {
            log.warning(String.format("Button caption '%s' is only supported for '%s' alert action", buttonLabel,
                    AlertAction.TAP_BUTTON.name()));
        }
        final Timedelta started = Timedelta.now();
        do {
            try {
                switch (action) {
                    case ACCEPT:
                        getDriver().switchTo().alert().accept();
                        return;
                    case DISMISS:
                        getDriver().switchTo().alert().dismiss();
                        return;
                    case TAP_BUTTON:
                        assert buttonLabel != null;
                        getElement(MobileBy.AccessibilityId(buttonLabel)).click();
                        return;
                    default:
                        throw new IllegalArgumentException(String.format("Illegal alert action '%s'", action.name()));
                }
            } catch (NoAlertPresentException e) {
                Timedelta.ofSeconds(1).sleep();
            }
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout));
        throw new IllegalStateException(
                String.format("No alert has been shown or it cannot be %s after %s",
                        (action == AlertAction.ACCEPT) ? "accepted" : "dismissed", timeout)
        );
    }

    public String getAlertTitle() {
        waitUntilLocatorVisible(classAlertTitle);
        return getDriver().findElement(classAlertTitle).getText();
    }

    public String getAlertDescription() {
        waitUntilLocatorVisible(classAlertDescription);
        return getDriver().findElement(classAlertDescription).getText();
    }

    public boolean isAlertContainsText(String expectedText) {
        final By locator = predicateAlertLabelByText.apply(expectedText);
        final Optional<WebElement> alert = getElementIfExists(classAlertTitle);
        return alert.isPresent() && isLocatorDisplayed(alert.get(), locator);
    }

    public static boolean isTablet() {
        return Config.current().isTablet(IOSPage.class);
    }

    public boolean isAlertDoesNotContainsText(String expectedText) {
        final By locator = predicateAlertLabelByText.apply(expectedText);
        final Optional<WebElement> alert = getElementIfExists(classAlertTitle);
        return alert.isEmpty() || isLocatorInvisible(alert.get(), locator);
    }

    public void putWireToBackgroundFor(Timedelta duration) {
        this.getDriver().runAppInBackground(duration.asDuration());
    }

    public void pressHomeButton() {
        getDriver().runAppInBackground(Duration.ofMillis(-1));
    }

    public void rotateScreen(ScreenOrientation orientation) {
        switch (orientation) {
            case LANDSCAPE:
                rotateLandscape();
                break;
            case PORTRAIT:
                rotatePortrait();
                break;
            default:
                throw new IllegalArgumentException(String.format("Unknown orientation '%s'",
                        orientation));
        }
    }

    private void rotateLandscape() {
        this.getDriver().rotate(ScreenOrientation.LANDSCAPE);
    }

    private void rotatePortrait() {
        this.getDriver().rotate(ScreenOrientation.PORTRAIT);
    }

    public void lockScreen(Timedelta duration) {
        this.getDriver().lockDevice(duration.asDuration());
    }

    protected void tapElementWithRetryIfStillDisplayed(WebElement el, Timedelta delay, int retryCount) {
        int counter = 0;
        do {
            try {
                el.click();
            } catch (WebDriverException | IllegalStateException e) {
                log.fine(e.getMessage());
                continue;
            }
            if (isElementInvisible(el, delay)) {
                return;
            }
        } while (++counter < retryCount);
        throw new IllegalStateException(String.format("Locator %s is still displayed after %s tap retries",
                el, retryCount));
    }

    protected void tapElementWithRetryIfStillDisplayed(WebElement el) {
        tapElementWithRetryIfStillDisplayed(el, Timedelta.ofSeconds(3), DEFAULT_RETRY_COUNT);
    }

    protected void tapElementWithRetryIfNextElementNotAppears(By locator, By nextLocator, Timedelta delay, int retryCount) {
        int counter = 0;
        do {
            final Optional<WebElement> dstElement = getElementIfExists(locator);
            if (dstElement.isPresent()) {
                dstElement.get().click();
                if (isLocatorExist(nextLocator, delay)) {
                    return;
                }
            }
        } while (++counter < retryCount);
        throw new IllegalStateException(String.format("Locator %s did't appear", nextLocator));
    }

    //region Elements location

    protected WebElement getElement(WebElement parent, By locator) {
        return this.getElement(parent, locator,
                String.format("The element '%s' is not visible", locator),
                getDefaultLookupTimeout()
        );
    }

    @Deprecated // Please use @iOSXCUITFindBy or getDriver().findElement() instead
    protected WebElement getElement(By locator) {
        return this.getElement(locator,
                String.format("The element '%s' is not visible", locator),
                getDefaultLookupTimeout());
    }

    protected WebElement getElement(WebElement parent, By locator, String message) {
        return this.getElement(parent, locator, message, getDefaultLookupTimeout());
    }

    @Deprecated // Please use @iOSXCUITFindBy or getDriver().findElement() instead
    protected WebElement getElement(By locator, String message) {
        return this.getElement(locator, message, getDefaultLookupTimeout());
    }

    private static final double MAX_EXISTENCE_DELAY_MS = 2000.0;
    private static final long MIN_EXISTENCE_ITERATIONS_COUNT = 2;

    protected WebElement getElement(@Nullable WebElement parent, By locator, String message,
                                    Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el;
                if (parent == null) {
                    el = getDriver().findElement(locator);
                } else {
                    el = parent.findElement(locator);
                }
                if (el.isDisplayed()) {
                    return el;
                }
            } catch (WebDriverException e) {
                log.info("Failed to get element: " + e.getMessage());
            }
            log.fine(String.format("The element '%s' is still not visible after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        throw new IllegalStateException(message);
    }

    @Deprecated // Please use @iOSXCUITFindBy or getDriver().findElement() instead
    protected WebElement getElement(By locator, String message, Timedelta timeout) {
        return getElement(null, locator, message, timeout);
    }

    @Deprecated // please use waitUntilLocatorVisible()
    protected boolean isLocatorExist(By locator) {
        return this.isLocatorExist(locator, getDefaultLookupTimeout());
    }

    protected boolean isLocatorExist(By locator, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el = getDriver().findElement(locator);
                if (el != null) {
                    return true;
                }
            } catch (WebDriverException e) {
                // simply ignore
            }
            log.fine(String.format("The element '%s' is still not present after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        return false;
    }

    protected boolean isLocatorNotExist(By locator) {
        return isLocatorNotExist(locator, getDefaultLookupTimeout());
    }

    protected boolean isLocatorNotExist(By locator, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el = getDriver().findElement(locator);
                if (el == null) {
                    return true;
                }
            } catch (WebDriverException e) {
                return true;
            }
            log.fine(String.format("The element '%s' is still present after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        return false;
    }

    protected boolean isLocatorDisplayed(WebElement parent, By locator) {
        return this.isLocatorDisplayed(parent, locator, getDefaultLookupTimeout());
    }

    @Deprecated // please use waitUntilLocatorVisible()
    protected boolean isLocatorDisplayed(By locator) {
        return this.isLocatorDisplayed(locator, getDefaultLookupTimeout());
    }

    protected boolean isLocatorDisplayed(@Nullable WebElement parent, By locator, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el;
                if (parent == null) {
                    el = getDriver().findElement(locator);
                } else {
                    el = parent.findElement(locator);
                }
                if (el.isDisplayed()) {
                    return true;
                }
            } catch (WebDriverException e) {
                // simply ignore
            }
            log.fine(String.format("The element '%s' is still not visible after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        return false;
    }

    protected boolean isLocatorDisplayed(By locator, Timedelta timeout) {
        return isLocatorDisplayed(null, locator, timeout);
    }

    protected boolean isLocatorInvisible(By locator) {
        return this.isLocatorInvisible(locator, getDefaultLookupTimeout());
    }

    protected boolean isLocatorInvisible(WebElement parent, By locator) {
        return this.isLocatorInvisible(parent, locator, getDefaultLookupTimeout());
    }

    protected boolean isLocatorInvisible(@Nullable WebElement parent, By locator, Timedelta timeout) {
        // TODO: Replace while loop with FluentWait
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el;
                if (parent == null) {
                    el = getDriver().findElement(locator);
                } else {
                    el = parent.findElement(locator);
                }
                if (!el.isDisplayed()) {
                    return true;
                }
            } catch (WebDriverException e) {
                return true;
            }
            log.fine(String.format("The element '%s' is still visible after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        return false;
    }

    protected boolean isLocatorInvisible(By locator, Timedelta timeout) {
        return isLocatorInvisible(null, locator, timeout);
    }

    @Deprecated // Please use waitUntilElementInvisible
    protected boolean isElementInvisible(WebElement element) {
        return this.isElementInvisible(element, getDefaultLookupTimeout());
    }

    protected boolean isElementInvisible(WebElement el, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                if (!el.isDisplayed()) {
                    return true;
                }
            } catch (WebDriverException e) {
                return true;
            }
            log.fine(String.format("The element '%s' is still visible after %s",
                    el, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        return false;
    }

    protected boolean isElementVisible(WebElement element) {
        return this.isElementVisible(element, getDefaultLookupTimeout());
    }

    protected boolean isElementVisible(WebElement el, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                if (el.isDisplayed()) {
                    return true;
                }
            } catch (WebDriverException e) {
                // Element might not exist yet, ignore
            }
            log.fine(String.format("The element '%s' is still invisible after %s",
                    el, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout) ||
                iterationNumber <= MIN_EXISTENCE_ITERATIONS_COUNT);
        return false;
    }

    protected Optional<WebElement> getElementIfDisplayed(@Nullable WebElement parent, By locator, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el;
                if (parent == null) {
                    el = getDriver().findElement(locator);
                } else {
                    el = parent.findElement(locator);
                }
                if (el.isDisplayed()) {
                    return Optional.of(el);
                }
            } catch (WebDriverException e) {
                // simply ignore
            }
            log.fine(String.format("The element '%s' is still not visible after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout));
        return Optional.empty();
    }

    protected Optional<WebElement> getElementIfDisplayed(By locator, Timedelta timeout) {
        return getElementIfDisplayed(null, locator, timeout);
    }

    protected Optional<WebElement> getElementIfExists(By locator) {
        return this.getElementIfExists(locator, getDefaultLookupTimeout());
    }

    protected Optional<WebElement> getElementIfExists(By locator, Timedelta timeout) {
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            try {
                final WebElement el = getDriver().findElement(locator);
                if (el != null) {
                    return Optional.of(el);
                }
            } catch (WebDriverException e) {
                // simply ignore
            }
            log.fine(String.format("The element '%s' is still not present after %s",
                    locator, Timedelta.now().diff(started).toString()));
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout));
        return Optional.empty();
    }

    protected List<WebElement> selectVisibleElements(By locator) {
        return selectVisibleElements(null, locator, getDefaultLookupTimeout());
    }

    protected List<WebElement> selectVisibleElements(@Nullable WebElement parent, By locator) {
        return selectVisibleElements(parent, locator, getDefaultLookupTimeout());
    }

    protected List<WebElement> selectVisibleElements(By locator, Timedelta timeout) {
        return selectVisibleElements(null, locator, timeout);
    }

    protected List<WebElement> selectVisibleElements(@Nullable WebElement parent, By locator, Timedelta timeout) {
        return selectElements(parent, locator, timeout)
                .stream()
                .filter(WebElement::isDisplayed)
                .collect(Collectors.toList());
    }

    protected List<WebElement> selectElements(@Nullable WebElement parent, By locator, Timedelta timeout) {
        final List<WebElement> result = new ArrayList<>();
        final Timedelta started = Timedelta.now();
        int iterationNumber = 1;
        do {
            if (parent == null) {
                result.addAll(getDriver().findElements(locator));
            } else {
                result.addAll(parent.findElements(locator));
            }
            if (result.size() > 0) {
                return result;
            }
            Timedelta.ofMillis(MAX_EXISTENCE_DELAY_MS / iterationNumber).sleep();
            iterationNumber++;
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout));
        return result;
    }

    //endregion

    @Deprecated // Please create individual page and step classes for such buttons
    public void tapCancelButton() {
        waitUntilElementClickable(cancelButton);
        cancelButton.click();
    }

    public void installApp(File appFile) {
        getDriver().installApp(appFile.getAbsolutePath());
        // simctl returns too early sometimes
        Timedelta.ofSeconds(3).sleep();
    }

    private static Point sizePercentsToRelativeCoordinates(WebElement el, int percentX, int percentY) {
        final Rectangle elRect = el.getRect();
        final int tapX = elRect.width * percentX / 100;
        final int tapY = elRect.height * percentY / 100;
        return new Point(tapX, tapY);
    }

    protected void longTapWithScript(WebElement el) {
        getDriver().executeScript("mobile: touchAndHold",
                ImmutableMap.of("element", ((RemoteWebElement) el).getId(),
                        "duration", (Duration.ofSeconds(3).toMillis() * 1.0 / 1000)));
    }

    protected void longTapWithScript(WebElement el, int percentX, int percentY) {
        final Point tapPoint = sizePercentsToRelativeCoordinates(el, percentX, percentY);
        getDriver().executeScript("mobile: touchAndHold",
                ImmutableMap.of("element", ((RemoteWebElement) el).getId(),
                        "x", tapPoint.x,
                        "y", tapPoint.y,
                        "duration", (Duration.ofSeconds(3).toMillis() * 1.0 / 1000)));
    }

    protected void longTapWithActionsAPI(WebElement el) throws InterruptedException {
        longTapWithActionsAPI(el, Duration.ofSeconds(2));
    }

    protected void longTapWithActionsAPI(WebElement el, Duration duration) throws InterruptedException {
        Actions actions = new Actions(getDriver());
        actions.moveToElement(el).clickAndHold().pause(duration).release().perform();
    }

    protected void tapByPercentOfElementSize(WebElement el, int percentX, int percentY) {
        //TODO adjust method to calculate offset needed instead of by percentage, or refactor to remove behaviour in general
        final Point tapPoint = sizePercentsToRelativeCoordinates(el, percentX, percentY);

        Actions actions = new Actions(getDriver());
        actions.click(el).perform();
    }

    protected void tapAtTheCenterOfElement(WebElement el) {
        tapByPercentOfElementSize(el, 50, 50);
    }

    protected void tapAtTheLeftSideOfElement(WebElement el) {
        Actions actions = new Actions(getDriver());
        actions.click(el).perform();
    }

    protected void tapScreenAt(int x, int y) {
        getDriver().executeScript("mobile: tap",
                ImmutableMap.of("x", x,
                        "y", y));
    }

    public void tapScreenByPercents(int percentX, int percentY) {
        final Dimension size = getDriver().manage().window().getSize();
        tapScreenAt(percentX * size.getWidth() / 100, percentY * size.getHeight() / 100);
    }

    public Optional<String> readAlertText() {
        return readAlertText(getDefaultLookupTimeout());
    }

    private Optional<String> readAlertText(Timedelta timeout) {
        final Timedelta start = Timedelta.now();
        do {
            try {
                final String text = getDriver().switchTo().alert().getText();
                if (text != null && text.length() > 0 && !text.equals("null") && !text.equals("{}")) {
                    return Optional.of(text);
                }
            } catch (WebDriverException e) {
                Timedelta.ofSeconds(1).sleep();
            }
        } while (Timedelta.now().isDiffLessOrEqual(start, timeout));
        return Optional.empty();
    }

    public void tapAlertButton(String caption) {
        handleAlert(AlertAction.TAP_BUTTON, caption, getDefaultLookupTimeout());
    }

    public boolean isAlertButtonVisible(String caption) {
        HashMap<String, String> args = new HashMap<>();
        args.put("action", "getButtons");
        List<String> buttons = (List<String>) getDriver().executeScript("mobile: alert", args);

        for (String button : buttons) {
            if (button.equals(caption)) {
                return true;
            }
        }
        return false;
    }

    public Optional<BufferedImage> takeScreenshot() {
        Optional<BufferedImage> screenshotImage;
        try {
            screenshotImage = takeFullScreenShot();
        } catch (Exception e) {
            return Optional.empty();
        }
        if (screenshotImage.isPresent()) {
            final Dimension screenSize = getDriver().manage().window().getSize();
            if (screenshotImage.get().getWidth() != screenSize.getWidth()) {
                // proportions are expected to be the same
                final double scale = 1.0 * screenSize.getWidth() / screenshotImage.get().getWidth();
                screenshotImage = Optional.of(
                        ImageUtil.resizeImage(screenshotImage.get(), (float) scale)
                );
            }
        }
        return screenshotImage;
    }

    public Optional<BufferedImage> getElementScreenshot(WebElement element) {
        final byte[] srcImage = element.getScreenshotAs(OutputType.BYTES);
        try {
            return Optional.ofNullable(ImageIO.read(new ByteArrayInputStream(srcImage)));
        } catch (IOException e) {
            e.printStackTrace();
            return Optional.empty();
        }
    }

    public boolean isDefaultMapApplicationVisible() {
        return waitUntilElementVisible(mapsApplicationButton);
    }

    public LogEntries getCrashLogs() {
        return getDriver().manage().logs().get(CRASHLOG);
    }

    public LogEntries getAppiumLogs() {
        return getDriver().manage().logs().get(SERVER_LOG);
    }

    public List<String> getWireLogs() {
        final String currentLogPath = String.format(Config.current().isSimulator(getClass())
                        ? "@%s:data/Library/Caches/current.log"
                        : "@%s/Library/Caches/current.log",
                Lifecycle.getBundleId());
        try {
            final byte[] content = getDriver().pullFile(currentLogPath);
            final String logContent = new String(content, Charset.forName("UTF-8"));
            return Arrays.asList(logContent.split("\n"));
        } catch (WebDriverException e) {
            e.printStackTrace();
        }
        return Collections.emptyList();
    }

    public enum SwipeDirection {
        UP, DOWN, LEFT, RIGHT
    }

    public void swipe(SwipeDirection direction) {
        swipe(null, direction);
    }

    protected WebElement swipe(@Nullable WebElement el, SwipeDirection direction) {
        final Map<String, Object> args;
        if (el == null) {
            args = ImmutableMap.of("direction", direction.name().toLowerCase());
        } else {
            args = ImmutableMap.of("direction", direction.name().toLowerCase(),
                    "element", ((RemoteWebElement) el).getId());
        }
        getDriver().executeScript("mobile: swipe", args);
        return el;
    }
    public void setClipboard(String text) {
        getDriver().setClipboardText(text);
    }

    public void terminateApp(String bundleId) {
        getDriver().terminateApp(bundleId);
    }

    public void openURL(String url) {
        getDriver().get(url);
    }

    public void openDeepLink(String deeplink, String browser) {
        log.fine("deeplink: "+deeplink);
        this.activateApp(browser);
        this.openURL(deeplink);
    }

    public void activateApp(String bundleId) {
        getDriver().activateApp(bundleId);
    }

    /*
     * Former DriverUtils methods
     */

    protected static Timedelta getDefaultLookupTimeout() {
        return Timedelta.ofSeconds(getDefaultLookupTimeoutSeconds());
    }

    public static int getDefaultLookupTimeoutSeconds() {
        return Integer.parseInt(Config.current().getDriverTimeout(IOSPage.class));
    }

    public boolean waitUntilElementVisible(WebElement element) {
        return waitUntilElementVisible(element, Duration.ofSeconds(getDefaultLookupTimeoutSeconds()));
    }

    public boolean waitUntilElementVisible(WebElement element, Duration duration) {
        new WebDriverWait(getDriver(), duration)
                .ignoring(StaleElementReferenceException.class)
                .until(ExpectedConditions.visibilityOf(element));
        return element.isDisplayed();
    }

    public boolean waitUntilElementInvisible(WebElement element) {
        return waitUntilElementInvisible(element, Duration.ofSeconds(getDefaultLookupTimeoutSeconds()));
    }

    public boolean waitUntilElementInvisible(WebElement element, Duration timeout) {
        try {
            // For checking invisibility the implicit wait needs to be deactivated
            driver.manage().timeouts().implicitlyWait(0, TimeUnit.SECONDS);
            FluentWait<WebDriver> wait = new WebDriverWait(getDriver(), Duration.ofSeconds(getDefaultLookupTimeoutSeconds()))
                    .pollingEvery(Duration.ofMillis(500))
                    .ignoring(StaleElementReferenceException.class);
            // Unfortunately ExpectedConditions.invisibilityOf() cannot be used here, because selenium does not return
            // true on a NoSuchElementException when using an element (for invisibilityOfElementLocated it works)
            return wait.until((drv) -> {
                try {
                    return !element.isDisplayed();
                } catch (NoSuchElementException e) {
                    return true;
                }
            });
        } catch (TimeoutException e) {
            return false;
        } finally {
            driver.manage().timeouts().implicitlyWait(getDefaultLookupTimeoutSeconds(), TimeUnit.SECONDS);
        }
    }

    public boolean waitUntilElementClickable(WebElement element) {
        try {
            new WebDriverWait(getDriver(), Duration.ofSeconds(getDefaultLookupTimeoutSeconds()))
                    .ignoring(StaleElementReferenceException.class)
                    .until(ExpectedConditions.elementToBeClickable(element));
            Wait<? extends RemoteWebDriver> waitStopped = new FluentWait<>(getDriver())
                    .withTimeout(Duration.ofSeconds(getDefaultLookupTimeoutSeconds()))
                    .pollingEvery(Duration.ofMillis(100))
                    .ignoring(NoSuchElementException.class)
                    .ignoring(StaleElementReferenceException.class);
            waitStopped.until(elementStoppedMoving(element));
            return true;
        } catch (TimeoutException e) {
            return false;
        }
    }

    private ExpectedCondition<WebElement> elementStoppedMoving(final WebElement element) {
        return new ExpectedCondition<WebElement>() {

            private Point location = null;

            public WebElement apply(WebDriver driver) {
                if (element.isDisplayed()) {
                    Point currentLocation = element.getLocation();
                    if (currentLocation.equals(location)) {
                        return element;
                    }
                    location = currentLocation;
                }

                return null;
            }

            public String toString() {
                return "steadiness of element " + element;
            }
        };
    }

    public boolean waitUntilLocatorVisible(By locator) {
        return waitUntilLocatorVisible(locator, getDefaultLookupTimeout().asDuration());
    }

    public boolean waitUntilLocatorVisible(By locator, Duration duration) {
        new WebDriverWait(getDriver(), duration)
                .ignoring(StaleElementReferenceException.class)
                .until(ExpectedConditions.visibilityOfElementLocated(locator));
        return true;
    }

    public int waitUntilNumberOfElementsToBe(By locator, int number) {
        // very slow on real device, so we increase timeout by 3
        return new WebDriverWait(getDriver(), Duration.ofSeconds(getDefaultLookupTimeoutSeconds() * 3L))
                .ignoring(StaleElementReferenceException.class)
                .until(ExpectedConditions.numberOfElementsToBe(locator, number))
                .size();
    }

    public Optional<BufferedImage> takeFullScreenShot() {
        try {
            final byte[] srcImage = getDriver().getScreenshotAs(OutputType.BYTES);
            final BufferedImage bImageFromConvert = ImageIO.read(new ByteArrayInputStream(srcImage));
            return Optional.ofNullable(bImageFromConvert);
        } catch (WebDriverException | NoClassDefFoundError | IOException e) {
            log.severe("Selenium driver has failed to take the screenshot of the current screen!");
        }
        return Optional.empty();
    }

    public void pushFile(String fileName, String path) {
        try {
            getDriver().pushFile(fileName, new File(path));
        } catch (IOException inputOutputException) {
            inputOutputException.printStackTrace();
            throw new IllegalArgumentException(
                    String.format("Something went wrong while pushing the file %s to the device", path));
        }
    }

    public boolean doesFileExistOnDevice(String fileName) {
        try {
            getDriver().pullFile(fileName);
        } catch (WebDriverException e) {
            return false;
        }
        return true;
    }

    public List<String> waitUntilElementContainsQRCode(final WebElement element) {
        try {
            Wait<? extends RemoteWebDriver> wait = new FluentWait<>(getDriver())
                    .withTimeout(Duration.ofSeconds(getDefaultLookupTimeoutSeconds()))
                    .pollingEvery(Duration.ofSeconds(1))
                    .ignoring(NoSuchElementException.class)
                    .ignoring(StaleElementReferenceException.class);
            return wait.until(elementContainsQRCode(element));
        } catch (TimeoutException e) {
            return Collections.emptyList();
        }
    }

    private ExpectedCondition<List<String>> elementContainsQRCode(final WebElement element) {
        return driver -> {
            Optional<BufferedImage> screenshot = getElementScreenshot(element);
            if (screenshot.isEmpty()) {
                log.info("Could not get screenshot of element");
                return null;
            }
            BufferedImage actualImage = screenshot.get();
            List<String> codes;
            try {
                codes = QRCode.readMultipleCodes(actualImage);
            } catch (com.google.zxing.NotFoundException e) {
                log.info("Element contains no QR code");
                return null;
            }
            if (codes.isEmpty()) {
                return null;
            } else {
                return codes;
            }
        };
    }

    private static final String SAFARI = "com.apple.mobilesafari";

    public void openDeepLinkForDefault() {
        Backend backend = BackendConnections.getDefault();
        String protocolHandler = "wire";

        if (backend.getBackendName().contains("column")) {
            protocolHandler = backend.getBackendName().contains("column-1") ? "wire-bk-test" : "wire-c3-test";
        }

        String deeplink = backend.getDeeplinkForiOS(protocolHandler);
        log.fine("deeplink: " + deeplink);
        activateApp(SAFARI);
        openURL(deeplink);
    }

    public void startVerificationEmailMonitoring(ClientUser user, IOSTestContext context) throws Exception {
        final Map<String, String> expectedHeaders = new HashMap<>();
        expectedHeaders.put(WireMessage.ZETA_PURPOSE_HEADER_NAME, VerificationMessage.MESSAGE_PURPOSE);

        ISupportsMessagesPolling mailbox = MailboxProvider.getInstance(BackendConnections.get(user), user.getEmail());
        context.setVerificationMessage(mailbox.getMessage(expectedHeaders, VerificationMessage.ACTIVATION_TIMEOUT));
    }
}
