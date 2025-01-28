package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.BottomNavigationBarPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class BottomNavigationBarSteps {
    IOSTestContext context;

    public BottomNavigationBarSteps(IOSTestContext context) {
        this.context = context;
    }

    private BottomNavigationBarPage getBottomNavigationBarPage() {
        return context.getPagesCollection()
                .getPage(BottomNavigationBarPage.class);
    }

    /**
     * Open the corresponding view by tapping a button
     *
     */

    @Then("^I open archived conversations$")
    public void IOpenArchivedConversations() {
        getBottomNavigationBarPage().openArchivedConversations();
    }

    /**
     * Verify whether Archive button is visible at the bottom of conversations list
     *
     * @param shouldNotSee equals to null if Archive button should be visible
     */
    @Then("^I (do not )?see Archive button at the bottom of conversations list$")
    public void ISeeArchiveButton(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Archive button should be visible, but it's hidden",
                    getBottomNavigationBarPage().isArchiveButtonVisible());
        } else {
            assertThat("Archive button should be invisible, but it's visible",
                    getBottomNavigationBarPage().isArchiveButtonInvisible());
        }
    }

    /**
    @Then("^I tap Folder button in bottom navigation bar$")
    public void iTapFolderButton() {
        getBottomNavigationBarPage().tapGroupedConversationsButton();
    }
*/
    @Then("^I tap Conversations button in bottom navigation bar$")
    public void iTapRecentConversationsButton() {
        getBottomNavigationBarPage().tapRecentConversationsButton();
    }

    @When("^I open settings screen")
    public void iTapSettingsButton() {
        getBottomNavigationBarPage().tapSettingsButton();
    }

}
