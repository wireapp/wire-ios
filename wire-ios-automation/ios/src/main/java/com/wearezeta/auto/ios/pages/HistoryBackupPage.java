package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class HistoryBackupPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeCell[$type == 'XCUIElementTypeStaticText' AND value == 'Back Up Now'$]")
    private WebElement backUpNowButton;

    public static final Timedelta BACKUP_TIMEOUT = Timedelta.ofSeconds(15);

     public HistoryBackupPage(WebDriver driver) {
        super(driver);
    }

    public void initiateHistoryBackup() {
        backUpNowButton.click();
    }

    public boolean isBackupNowButtonShown() {
        return isElementVisible(backUpNowButton, BACKUP_TIMEOUT);
    }
}
