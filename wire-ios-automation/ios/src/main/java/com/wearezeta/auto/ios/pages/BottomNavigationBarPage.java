package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class BottomNavigationBarPage extends IOSPage {


    @iOSXCUITFindBy(accessibility = "bottomBarRecentListButton")
    private WebElement recentConversationsButton;

    /**
    @iOSXCUITFindBy(accessibility = "bottomBarFolderListButton")
    private WebElement folderButton;
*/
    @iOSXCUITFindBy(accessibility = "bottomBarArchivedButton")
    private WebElement openArchiveButton;

    @iOSXCUITFindBy(accessibility = "gearshape")
    WebElement settingsButton;

    public BottomNavigationBarPage(WebDriver driver) {
        super(driver);
    }


    public void openArchivedConversations() {
        tapElementWithRetryIfStillDisplayed(openArchiveButton);
    }

    public boolean isArchiveButtonVisible() {
        return openArchiveButton.isDisplayed();
    }

    public boolean isArchiveButtonInvisible() {
        return isElementInvisible(openArchiveButton);
    }

  /**  public void tapGroupedConversationsButton() {
        folderButton.click();
    }
*/
    public void tapRecentConversationsButton() {
        recentConversationsButton.click();
    }

    public void tapSettingsButton() {
        settingsButton.click();
    }
}
