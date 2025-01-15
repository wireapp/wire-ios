package com.wearezeta.auto.ios.common;

import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import com.wearezeta.auto.common.log.ZetaLogger;
import java.util.logging.Logger;

public class Pinger {

    public static final Logger log = ZetaLogger.getLog(Pinger.class.getSimpleName());

    // Should not be higher than session timeout on selenium grid
    private static final int PINGER_POLLING_PERIOD = 30;

    private final ScheduledThreadPoolExecutor PING_EXECUTOR = new ScheduledThreadPoolExecutor(1);
    private ScheduledFuture<?> RUNNING_PINGER;
    private IOSTestContext context;
    private final Runnable PINGER = new Runnable() {
        @Override
        public void run() {
            try {
                log.fine("Pinging driver");
                context.getDriver().manage().window().getSize();
            } catch (Exception ex) {
                log.warning(String.format("Could not ping driver: %s", ex.getMessage()));
            }
        }
    };

    public Pinger(IOSTestContext context) {
        PING_EXECUTOR.setRemoveOnCancelPolicy(true);
        this.context = context;
    }

    public void startPinging() {
        if (RUNNING_PINGER == null) {
            log.info("Scheduling pinger task");
            RUNNING_PINGER = PING_EXECUTOR.scheduleAtFixedRate(PINGER, 0, PINGER_POLLING_PERIOD, TimeUnit.SECONDS);
        } else {
            log.warning("Driver pinger is already running - Please stop the driver pinger before starting it again");
        }
    }

    public void stopPinging() {
        if (RUNNING_PINGER != null) {
            if (!RUNNING_PINGER.cancel(true)) {
                log.warning("Could not stop driver pinger");
            }
            RUNNING_PINGER = null;
        } else {
            log.warning("No pinger to stop");
        }
    }
}
