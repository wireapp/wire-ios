package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.pages.CreateFolderPage;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.When;

public class CreateFolderSteps {
    IOSTestContext context;

    public CreateFolderSteps(IOSTestContext context) {
        this.context = context;
    }

    private CreateFolderPage getNewFolderPage() {
        return context.getPagesCollection().getPage(CreateFolderPage.class);
    }

    @When("^I enter Folder name \"(.*)\" on New Folder page$")
    public void iEnterFoldernameOnNewFolderPage(String folderName) {
        getNewFolderPage().enterFolderName(folderName);
    }

    @When("^I tap Create button on New Folder page$")
    public void iTapCreateNewButton() {
        getNewFolderPage().tapCreateButton();
    }
}


