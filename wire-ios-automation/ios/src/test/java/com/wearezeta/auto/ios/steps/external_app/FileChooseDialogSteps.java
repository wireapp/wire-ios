package com.wearezeta.auto.ios.steps.external_app;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.external_app.FileChooseDialogPage;
import io.cucumber.java.en.When;

public class FileChooseDialogSteps {

    IOSTestContext context;

    public FileChooseDialogSteps(IOSTestContext context) {
        this.context = context;
    }

    private FileChooseDialogPage getPage() {
        return context.getPagesCollection().getPage(FileChooseDialogPage.class);
    }

    @When("^I tap Browse button twice on bottom of File Choose Dialog$")
    public void iTapBrowseFolders() {
        getPage().tapBrowseFoldersButton();
        getPage().tapBrowseFoldersButton();
    }

    @When("I tap Browse button of File Choose Dialog on iPad$")
    public void iTapBrowserFoldersOnIPad() {
        getPage().tapBrowserFolderButtonOnIPad();
    }

    @When("^I tap On My iPhone on File Choose Dialog$")
    public void iTapOnMyIPhone() {
        getPage().tapOnMyIPhone();
    }

    @When("^I tap On My iPad on File Choose Dialog$")
    public void iTapOnMyIPad() {
        getPage().tapOnMyIPad();
    }

    @When("^I sort files by date on File Choose Dialog$")
    public void iSortFilesByDate() {
        getPage().tapOnEllipsisButton();
        if (getPage().isSortByDateNotSelected()) {
            getPage().tapSortByDateEntry();
        }
        getPage().dismissEllipsisMenu();
    }

    @When("^I tap file containing (.*) in File Choose Dialog$")
    public void iTapFileContaining(String usernameAlias) {
        usernameAlias = context.getUsersManager().replaceAliasesOccurrences(usernameAlias,
                ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        getPage().tapFileContaining(usernameAlias);
    }
}
