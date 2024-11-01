package com.wearezeta.auto.ios.tablet.pages;

import java.util.concurrent.Future;

import com.wearezeta.auto.ios.pages.ConversationViewPage;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;

import org.openqa.selenium.WebDriver;


public class TabletConversationViewPage extends ConversationViewPage {
    private static final By nameOpenConversationDetails =
            MobileBy.AccessibilityId("ComposeControllerConversationDetailButton");

    public TabletConversationViewPage(WebDriver driver) {
        super(driver);
    }

    public void tapConversationDetailsIPadButton() {
        getElement(nameOpenConversationDetails).click();
    }
}
