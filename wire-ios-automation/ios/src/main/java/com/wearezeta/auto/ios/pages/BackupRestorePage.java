package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class BackupRestorePage extends IOSPage {

  @iOSXCUITFindBy(accessibility = "Back Up Now")
  WebElement backupAction;

  public BackupRestorePage(WebDriver driver) {
    super(driver);
  }

  public void startBackUp() {
    backupAction.click();
  }
}
