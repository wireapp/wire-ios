package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.When;

public class SettingsSteps extends IOSSteps {
  public SettingsSteps(IOSTestContext context) {
    super(context);
  }

  @When("I open the backup or restore options")
  public void iOpenBackupOrRestore() {
    getSettingsPage().openBackupRestore();
  }

  @When("I create a backup with \"(.*)\"")
  public void iCreateABackupWith(String backupPassword) {
    getBackupRestorePage().startBackUp();
    getBackupPasswordOverlayPage().givePassword(backupPassword);
    getBackupPasswordOverlayPage().waitForBackupToFinish();
    getBackupPasswordOverlayPage().saveFile();
  }

  @When("I restore my backup with \"(.*)\"")
  public void iRestoreMyBackup(String backupPassword) {
    getCommonPage().tapAlertButton("Choose Backup File");
    getFileChooseDialogPage().tapBrowseFoldersButton();
    getFileChooseDialogPage().tapBrowseFoldersButton();
    getFileChooseDialogPage().tapOnMyIPhone();

    String usernameAlias = context.getUsersManager().getSelfUser().get().getUniqueUsername();
    getFileChooseDialogPage().tapFileContaining(usernameAlias);

    getCommonPage().typeAlertText(backupPassword);
  }
}
