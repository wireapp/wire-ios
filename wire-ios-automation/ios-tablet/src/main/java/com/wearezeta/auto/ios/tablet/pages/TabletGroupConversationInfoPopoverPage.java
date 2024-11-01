package com.wearezeta.auto.ios.tablet.pages;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupDetailsPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import org.openqa.selenium.WebDriver;

public class TabletGroupConversationInfoPopoverPage extends GroupDetailsPage {
    private static final By namePopoverDismissRegion = MobileBy.AccessibilityId("PopoverDismissRegion");

    public TabletGroupConversationInfoPopoverPage(WebDriver driver) {
        super(driver);
    }

    public void dismissPopover() {
        // marked as inconsistent behaviour in 2017, but seems working again in 2019
        this.tapByPercentOfElementSize(
                getElementIfExists(namePopoverDismissRegion).orElseThrow(
                        () -> new IllegalStateException("Popover dismiss region is not present")
                ), 10, 10);
        // Wait for animation
        Timedelta.ofSeconds(1).sleep();
    }
}
