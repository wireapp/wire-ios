package com.wearezeta.auto.ios.pages;

import com.wearezeta.auto.common.misc.Timedelta;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.FluentWait;
import org.openqa.selenium.support.ui.Wait;

import java.time.Duration;

public class BackupPasswordOverlayPage extends IOSPage {

  @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeSecureTextField[`value == \"Enter password\"`]")
  private WebElement passwordInput;

  @iOSXCUITFindBy(accessibility = "Next")
  private WebElement nextButton;

  @iOSXCUITFindBy(accessibility = "back up now")
  private WebElement backUpNowButton;

  @iOSXCUITFindBy(accessibility = "progressLabel")
  private WebElement progress;

  @iOSXCUITFindBy(accessibility = "exportButton")
  WebElement saveFile;

  public BackupPasswordOverlayPage(WebDriver driver) {
    super(driver);
  }

  public void typePassword(String password) {
    waitUntilElementClickable(passwordInput);
    passwordInput.clear();
    passwordInput.sendKeys(password + "\n");
  }

  public void tapNextButton() {
    nextButton.click();
  }

  public void givePassword(String backupPassword) {
    typePassword(backupPassword);
    // Need to wait for the screen redraw after the enter key
    Timedelta.ofSeconds(1).sleep();
    backUpNowButton.click();
  }

  public void saveFile() {
    waitUntilElementVisible(saveFile);
    waitUntilElementClickable(saveFile);
    saveFile.click();
  }

  public void waitForBackupToFinish() {
    waitUntilElementVisible(progress);
    Wait<WebDriver> wait = new FluentWait<>(driver)
        .withTimeout(Duration.ofSeconds(10))
        .pollingEvery(Duration.ofSeconds(2))
        .ignoring(NoSuchElementException.class);
    wait.until(ExpectedConditions.attributeToBe(progress, "value", "100%"));
  }
}
