package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.pages.MoveToCustomFolderPage;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class MoveToCustomFolderSteps {
    IOSTestContext context;

    public MoveToCustomFolderSteps(IOSTestContext context) {
        this.context = context;
    }

    private MoveToCustomFolderPage getMoveToCustomFolderPage() {
        return context.getPagesCollection().getPage(MoveToCustomFolderPage.class);
    }

    @Given("^I (do not )?see Move to Custom Folder page$")
    public void ISeeMoveToPage(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Move to Custom Folder page is not visible after the timeout",
                    getMoveToCustomFolderPage().isVisible());
        } else {
            assertThat("Move to Custom Folder page is still visible after the timeout",
                    getMoveToCustomFolderPage().isInvisible());
        }
    }

    @When("^I tap Create button on Custom Folder page$")
    public void iTapCreateNewButton() {
        getMoveToCustomFolderPage().tapCreateNewButton();
    }

    @When("^I tap folder \"(.*)\" on Custom Folder page$")
    public void iTapACustomFolder(String folderName) {
        getMoveToCustomFolderPage().tapOnACustomFolder(folderName);
    }
}
