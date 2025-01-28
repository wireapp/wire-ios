package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.Config;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.cucumber.java.en.When;

public class BiometricAuthSteps {
    IOSTestContext context;

    public BiometricAuthSteps(IOSTestContext context) {
        this.context = context;
    }

    private static void verifyCurrentDeviceIsSimulator() {
        if (!Config.current().isSimulator(BiometricAuthSteps.class)) {
            throw new IllegalStateException("The current device is expected to be an iOS Simulator");
        }
    }

    /**
     * Perform simulated touch ID on Simulator. It is mandatory that Touch ID feature
     * is already enrolled
     *
     * @param type either 'successful' or 'failed)'
     * @
     */
    @When("^I perform (successful|failed) Touch ID$")
    public void IPerformTouchID(String type)  {
        verifyCurrentDeviceIsSimulator();
        // Consistently needed to wait 2 seconds before sending the perform for it to be accepted
        context.startPinging();
        Timedelta.ofSeconds(2).sleep();
        context.stopPinging();
        context.getPagesCollection().getPage(IOSPage.class)
                .performTouchID(type.equalsIgnoreCase("successful"));
    }
}
