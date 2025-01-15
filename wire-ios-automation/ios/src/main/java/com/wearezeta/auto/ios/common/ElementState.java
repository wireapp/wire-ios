package com.wearezeta.auto.ios.common;

import com.wearezeta.auto.common.ImageUtil;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.misc.Timedelta;
import java.util.logging.Logger;
import org.openqa.selenium.StaleElementReferenceException;

import java.awt.image.BufferedImage;
import java.util.Optional;
import java.util.function.Function;
import java.util.function.Supplier;


public class ElementState {
    private static final Logger log = ZetaLogger.getLog(ElementState.class.getSimpleName());

    private static final Timedelta INTERVAL = Timedelta.ofMillis(500);

    private Optional<BufferedImage> previousScreenshot = Optional.empty();
    private Supplier<BufferedImage> screenshotFunction;

    public ElementState(Supplier<BufferedImage> screenshotFunction) {
        this.screenshotFunction = screenshotFunction;
    }

    public ElementState remember() throws Exception {
        final int maxRetries = 3;
        int nTry = 0;
        Exception savedException;
        do {
            try {
                this.previousScreenshot = Optional.of(screenshotFunction.get());
                return this;
            } catch (StaleElementReferenceException e) {
                savedException = e;
                nTry++;
                INTERVAL.sleep();
            }
        } while (nTry < maxRetries);
        throw savedException;
    }

    private boolean checkState(Function<Double, Boolean> checkerFunc, Timedelta timeout) {
        return checkState(checkerFunc, timeout, ImageUtil.RESIZE_TEMPLATE_TO_REFERENCE_RESOLUTION);
    }

    private boolean checkState(Function<Double, Boolean> checkerFunc, Timedelta timeout, int resizeMode) {
        final Timedelta started = Timedelta.now();
        do {
            try {
                final BufferedImage currentState = screenshotFunction.get();
                final double score = ImageUtil.getOverlapScore(
                        this.previousScreenshot.orElseThrow(
                                () -> new IllegalStateException("Please remember the previous element state first")),
                        currentState, resizeMode);
                log.fine(String.format("Actual score: %.4f; Time left: %s", score,
                        timeout.sum(started).diff(Timedelta.now()).toString()));
                if (checkerFunc.apply(score)) {
                    return true;
                }
            } catch (StaleElementReferenceException e) {
                log.fine(String.format("Actual score: <calculation error>; Time left: %s",
                        timeout.sum(started).diff(Timedelta.now()).toString()));
            }
            INTERVAL.sleep();
        } while (Timedelta.now().isDiffLessOrEqual(started, timeout));
        return false;
    }

    public boolean isChanged(Timedelta timeout, double minScore) {
        log.fine(String.format(
                "Checking if element state has been changed in %s (Min score: %.4f)...",
                timeout.toString(), minScore));
        return checkState((x) -> x < minScore, timeout);
    }

    public boolean isNotChanged(Timedelta timeout, double minScore) {
        log.fine(String.format(
                "Checking if element state has NOT been changed in %s (Min score: %.4f)...",
                timeout, minScore));
        return checkState((x) -> x >= minScore, timeout);
    }
}
