package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class BackupRestorePage extends IOSPage {

  @iOSXCUITFindBy(accessibility = "Back Up Now")
  WebElement backupAction;

  @iOSXCUITFindBy(accessibility = "Restore from Backup")
  WebElement restoreAction;

  @iOSXCUITFindBy(accessibility = "Proceed")
  WebElement proceed;

  @iOSXCUITFindBy(accessibility = "password input")
  WebElement password;

  @iOSXCUITFindBy(accessibility = "Continue")
  WebElement continueButton;

  public BackupRestorePage(WebDriver driver) {
    super(driver);
  }

  public void startBackUp() {
    backupAction.click();
  }

  public void startRestore() {
    restoreAction.click();
  }

  public void restoreProceed() {
    proceed.click();
  }

  public void inputRestorePassword(String backupPassword) {
    waitUntilElementVisible(password);
    password.sendKeys(backupPassword);
    waitUntilElementClickable(continueButton);
    continueButton.click();
  }
}
