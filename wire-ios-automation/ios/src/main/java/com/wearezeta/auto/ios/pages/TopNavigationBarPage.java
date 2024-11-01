package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class TopNavigationBarPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "bottomBarSettingsButton")
    private WebElement profileButton;

    @iOSXCUITFindBy(accessibility = "legalhold")
    private WebElement legalHoldIndicator;


//  @iOSXCUITFindBy(accessibility = "Name")
//    private WebElement userProfileName;
//

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeNavigationBar[`name == \"Conversations\"`]/XCUIElementTypeOther/XCUIElementTypeButton/XCUIElementTypeOther[1]/XCUIElementTypeImage")
    private WebElement userProfileImage;

    @iOSXCUITFindBy(accessibility = "create_group_or_search_button")
    private WebElement  openSearchScreenButton;

    @iOSXCUITFindBy(accessibility = "Filter conversations")
    private WebElement filterButton;

    public TopNavigationBarPage(WebDriver driver) {
        super(driver);
    }

    public void tapProfileButton() {
        waitUntilElementClickable(profileButton);
        profileButton.click();
    }

    public boolean isSelfProfileButtonVisible() {
        return profileButton.isDisplayed();
    }

    public boolean isSelfProfileButtonInvisible() {
        return waitUntilElementInvisible(profileButton);
    }

    public void tapProfileImage() {
        userProfileImage.click();
    }

    public boolean isLegalHoldIndicatorVisible() {
        return waitUntilElementVisible(legalHoldIndicator);
    }

    public boolean isLegalHoldIndicatorInvisible() {
        return waitUntilElementInvisible(legalHoldIndicator);
    }

    public void iTapLegalHoldIndicator() {
        legalHoldIndicator.click();
    }
    public void iOpenSearchScreen() {
        openSearchScreenButton.click();
    }

    public void iTapOnFilterButton() {
        filterButton.click();
    }
}
