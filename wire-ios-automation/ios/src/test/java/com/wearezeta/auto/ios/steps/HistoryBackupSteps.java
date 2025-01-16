package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.HistoryBackupPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.*;

public class HistoryBackupSteps {

    IOSTestContext context;

    public HistoryBackupSteps(IOSTestContext context) {
        this.context = context;
    }

    private HistoryBackupPage getPage() {
        return context.getPagesCollection().getPage(HistoryBackupPage.class);
    }

    @When("^I initiate history backup from Settings$")
    public void iInitiateHistoryBackupFromSettings() {
        getPage().initiateHistoryBackup();
    }

    @Then("^I verify history backup for user (.*) from Settings is successfully completed$")
    public void iVerifyHistoryBackupIsSuccessful(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        assertThat("Backup now button is not back", getPage().isBackupNowButtonShown());

            // The files can be found under ~/Library/Developer/CoreSimulator/Devices/65061465-C2A1-4F3E-AEE6-E48C4E89D2B6/data/Containers/Shared/AppGroup/4806084A-DA44-4A49-A07F-9FC69E516F7D/File Provider Storage/Wire-5u4asoh3-Backup_20210204.ios_wbu
            // But i was unable to find the correct app group hash to get them
            // Appium is running "xcrun simctl get_app_container 65061465-C2A1-4F3E-AEE6-E48C4E89D2B6 com.wearezeta.zclient.ios-development groups"
            // when using pullFile("@com.wearezeta.zclient.ios-development:groups/<file>") but this returns a wrong app group hash.
            // Neither com.apple.DocumentsApp nor com.apple.FileProvider.LocalStorage works
            // See also https://stackoverflow.com/a/58299287
        /*
        final TimeZone timezone = TimeZone.getTimeZone("UTC");
        DateFormat dateFormat = new SimpleDateFormat("yyyyMMdd");
        dateFormat.setTimeZone(timezone);
        byte[] file = getPage().getBackupFile("com.wearezeta.zclient.ios-development", user.getUniqueUsername(), dateFormat.format(new Date()));
        assertThat("Backup file has no content", file.length, greaterThan(0));
         */
    }
}
