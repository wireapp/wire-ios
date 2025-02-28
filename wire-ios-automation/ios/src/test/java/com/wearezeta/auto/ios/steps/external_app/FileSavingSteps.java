package com.wearezeta.auto.ios.steps.external_app;

import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.external_app.FileSavingPopupPage;
import io.cucumber.java.en.When;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.containsString;

public class FileSavingSteps {

    IOSTestContext context;

    public FileSavingSteps(IOSTestContext context) {
        this.context = context;
    }

    private FileSavingPopupPage getPage() {
        return context.getPagesCollection().getPage(FileSavingPopupPage.class);
    }

    @When("^I see correct name of backup file for user (.*) on File Saving Popup$")
    public void iSeeNameOfFile(String userAlias) {
        ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(userAlias);
        assertThat("File name in label does not contain user name",
                getPage().getFileLabel(), containsString(user.getUniqueUsername()));

        final TimeZone timezone = TimeZone.getTimeZone("Europe/Berlin");
        DateFormat dateFormat = new SimpleDateFormat("yyyyMMdd");
        dateFormat.setTimeZone(timezone);
        String filename = String.format("Wire-%s-Backup_%s", user.getUniqueUsername(), dateFormat.format(new Date()));
        assertThat("File name in label does not contain correct filename",
                getPage().getFileLabel(), containsString(filename));
    }

    @When("^I tap Save to Files button on File Saving Popup$")
    public void iTapSaveToFiles() {
        getPage().tapSaveToFilesButton();
    }

    @When("^I tap On My iPhone on File Saving Popup$")
    public void iTapOnMyIPhone() {
        getPage().tapOnMyIPhone();
    }

    @When("^I tap On My iPad on File Saving Popup$")
    public void iTapOnMyIPad() {
        getPage().tapOnMyIPad();
    }

    @When("^I tap Save button on File Saving Popup$")
    public void iTapSave() {
        getPage().tapSaveButton();
    }
}
