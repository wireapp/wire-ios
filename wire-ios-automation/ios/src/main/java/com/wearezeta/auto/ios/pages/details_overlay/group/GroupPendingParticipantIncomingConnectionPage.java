package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import java.util.function.Function;

public class GroupPendingParticipantIncomingConnectionPage extends IOSPage {

    private static final Function<String, By> predicateNameByValue = name -> MobileBy.iOSNsPredicateString(
            String.format("type == 'XCUIElementTypeStaticText' AND name IN {'user_profile.name','name'} AND value == '%s'",
                    name));

    public GroupPendingParticipantIncomingConnectionPage(WebDriver driver) {
        super(driver);
    }

    public boolean isUserDetailNameVisible(String name) {
        return isLocatorDisplayed(predicateNameByValue.apply(name));
    }
}
