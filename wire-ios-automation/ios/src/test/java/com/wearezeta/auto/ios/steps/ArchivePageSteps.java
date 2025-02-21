package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ArchivePage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

import java.util.regex.Pattern;

public class ArchivePageSteps {
    IOSTestContext context;

    public ArchivePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ArchivePage getArchivePage() {
        return context.getPagesCollection()
                .getPage(ArchivePage.class);
    }

    /**
     * Tap close button on Archive page
     */
    @When("^I tap close Archive page button$")
    public void IClickCloseArchivePageButton() {
        getArchivePage().clickCloseArchivePageButton();
    }

    /**
     * verifies the visibility of a specific item in the archived conversations list
     *
     * @param shouldNotSee equals to null if the item should be visible
     * @param value        conversation name/alias
     */
    @Then("^I (do not )?see conversation (.*) in archived conversations list$")
    public void ISeeUserInContactList(String shouldNotSee, String value) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("The conversation '%s' is not visible in the conversation list",
                    value), getArchivePage().isConversationInList(value));
        } else {
            assertThat(
                    String.format("The conversation '%s' is visible in the conversation list, but should be hidden",
                            value), getArchivePage().isConversationNotInList(value));
        }
    }

    /**
     * Open the corresponding conversation by tapping its name in the conversations list
     *
     * @param name conversation name/alias
     */
    @Given("^I open archived (?:group |single |1:1 |\\s?)conversation \"(.*)\"")
    public void IOpenArchivedConversation(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getArchivePage().tapConversationsListItem(name);
    }
}
