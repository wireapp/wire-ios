package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.FolderViewPage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;

import java.util.regex.Pattern;

public class FolderViewSteps {
    IOSTestContext context;

    public FolderViewSteps(IOSTestContext context) {
        this.context = context;
    }

    private FolderViewPage getFolderViewPage() {
        return context.getPagesCollection()
                .getPage(FolderViewPage.class);
    }

    @Given("^I see Folder view$")
    public void ISeeFolderView() {
        assertThat("Folder view is not visible after the timeout",
                getFolderViewPage().isVisible());
    }

    /**
     * Open the corresponding conversation by tapping its name in the conversations list
     *
     * @param name conversation name/alias
     */
    @Given("^I open (?:group |single |1:1 |\\s?)conversation \"(.*)\" in Folder view")
    public void IOpenRecentConversation(String name) {
        name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getFolderViewPage().tapConversationItemGroupedList(name);
    }

    @Then("^I see People folder in Folder view$")
    public void iSeePeopleFolder() {
        assertThat("People folder is not visible", getFolderViewPage().isPeopleFolderVisible());
    }

    /**
     * verifies the visibility of the Favorites folder in Folder view
     *
     * @param shouldNotSee equals to null if the item should be visible
     */
    @Then("^I (do not )?see Favorites folder in Folder view$")
    public void ISeeFavoritesFolder(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Favorites folder is not visible", getFolderViewPage().isFavoritesFolderVisible());
        } else {
            assertThat("Favorites folder is not visible", getFolderViewPage().isFavoritesFolderInvisible());
        }
    }

    /**
     * Taps the People folder to collapse the folder
     */
    @Then("^I (collapse|expand) People folder$")
    public void ITapPeopleFolder() {
        getFolderViewPage().tapPeopleFolder();
    }

    /**
     * Taps the Favorites folder to collapse the folder
     */
    @Then("^I (collapse|expand) Favorites folder$")
    public void ITapFavoritesFolder() {
        getFolderViewPage().tapFavoritesFolder();
    }

    /**
     * Taps the custom folder to collapse the folder
     * @param folderName name of the custom folder
     */
    @Then("^I (collapse|expand) custom folder (.*)$")
    public void ITapCustomFolder(String folderName) {
        getFolderViewPage().tapCustomFolder(folderName);
    }

    /**
     * Taps the People folder to collapse the folder
     */
    @Then("^I see People folder is (collapsed|expanded)$")
    public void ISeePeopleFolderExpanded(String state) {
        if (state.equals("collapsed")) {
            getFolderViewPage().isFolderCollapsed("People");
        } else {
            getFolderViewPage().isFolderExpanded("People");
        }
    }

    /**
     * verifies the visibility of the Groups folder in grouped conversation list
     *
     * @param shouldNotSee equals to null if the item should be visible
     */
    @Then("^I (do not )?see Groups folder in Folder view$")
    public void ISeeGroupsFolder(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Group folder is not visible", getFolderViewPage().isGroupFolderVisible());
        } else {
            assertThat("Group folder is not visible", getFolderViewPage().isGroupFolderInvisible());
        }
    }

    /**
     * verifies the visibility of a custom folder in grouped conversation list
     *
     * @param shouldNotSee equals to null if the item should be visible
     * @param folderName   the name of the custom folder
     */
    @Then("^I (do not )?see custom folder (.*) in Folder view$")
    public void ISeeGroupsFolder(String shouldNotSee, String folderName) {
        if (shouldNotSee == null) {
            assertThat("Group folder is not visible", getFolderViewPage().isCustomFolderVisible(folderName));
        } else {
            assertThat("Group folder is not visible", getFolderViewPage().isCustomFolderInvisible(folderName));
        }
    }

    @Then("^I see conversation (.*) in People folder$")
    public void iSeeUserInContactFolder(String value) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS);
        assertThat("The conversation is not visible in the People folder",
                getFolderViewPage().getConversationOfPeopleFolder(), hasItem(value));
    }

    @Then("^I do not see conversation (.*) in People folder$")
    public void iDoNotSeeUserInContactFolder(String value) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS);
        if (!getFolderViewPage().isPeopleFolderInvisible()) {
            assertThat("The conversation is visible in the People folder, but should be hidden",
                    getFolderViewPage().getConversationOfPeopleFolder(), not(hasItem(value)));
        }
    }

    /**
     * verifies the visibility of a specific conversation in the People folder
     *
     * @param shouldNotSee equals to null if the item should be visible
     * @param value        conversation name/alias
     */
    @Then("^I (do not )?see conversation (.*) in Groups folder$")
    public void ISeeUserInGroupFolder(String shouldNotSee, String value) {
        if (shouldNotSee == null) {
            assertThat(String.format("The conversation '%s' is not visible in the Groups list",
                    value), getFolderViewPage().isConversationInGroupsFolder(value));
        } else {
            assertThat(
                    String.format("The conversation '%s' is visible in the Groups list, but should be hidden",
                            value), getFolderViewPage().isConversationNotInGroupsFolder(value));
        }
    }

    /**
     * verifies the visibility of a specific conversation in the Favorites folder
     *
     * @param shouldNotSee equals to null if the item should be visible
     * @param value        conversation name/alias
     */
    @Then("^I (do not )?see conversation (.*) in Favorites folder$")
    public void ISeeUserInFavoritesFolder(String shouldNotSee, String value) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("The conversation '%s' is not visible in the Favorites list",
                    value), getFolderViewPage().isConversationInFavoritesFolder(value));
        } else {
            assertThat(
                    String.format("The conversation '%s' is visible in the Favorites list, but should be hidden",
                            value), getFolderViewPage().isConversationNotInFavoritesFolder(value));
        }
    }

    /**
     * verifies the visibility of a specific conversation in a specific folder
     *
     * @param shouldNotSee equals to null if the item should be visible
     * @param value        conversation name/alias
     * @param folderName   the name of the folder that should contain the conversation
     */
    @Then("^I (do not )?see conversation (.*) in custom folder (.*)$")
    public void ISeeUserInGroupFolder(String shouldNotSee, String value, String folderName) {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat("The conversation is not visible in custom folder",
                    getFolderViewPage().getConversationsInCustomFolder(folderName), hasItem(value));
        } else {
            assertThat(
                    "The conversation is visible in the custom folder, but should not",
                    getFolderViewPage().getConversationsInCustomFolder(folderName), not(hasItem(value)));
        }
    }

    /**
     * Check value of status icon in conversation list
     *
     * @param status       the number of unread messages in the status icon
     * @param conversation the unread messages are in
     */
    @Then("^I see status of Folder view conversation item (.*) is (not )?(\\d+|ping|Pinged|missed call|active call|Silenced|you are mentioned|You are mentioned)$")
    public void ISeeConversationStatus(String conversation, String notChanged, String status) {
        conversation = context.getUsersManager()
                .replaceAliasesOccurrences(conversation, ClientUsersManager.FindBy.NAME_ALIAS);
        if (notChanged == null) {
            assertThat(String.format("The current status for conversation item %s is not equal to %s",
                    conversation, status),
                    getFolderViewPage().isConversationItemWithStatusVisible(status, conversation));
        } else {
            assertThat(String.format("The current status for conversation item %s is not expected to be equal " +
                            "to %s",
                    conversation, status),
                    getFolderViewPage().isConversationItemWithStatusInvisible(status, conversation));
        }
    }

    @Then("^I (do not )?see the secondary line of Folder view conversation item (.*) is \"(.*)\"$")
    public void ISeeTheSecondaryIs(String doNot, String conversation, String secondaryLine) {
        conversation = context.getUsersManager()
                .replaceAliasesOccurrences(conversation, ClientUsersManager.FindBy.NAME_ALIAS);
        final Pattern usernamePattern = Pattern.compile(ClientUsersManager.
                STR_UNIQUE_USERNAME_ALIAS_TEMPLATE.apply("\\d+"));
        if (usernamePattern.matcher(secondaryLine).find()) {
            secondaryLine = context.getUsersManager()
                    .replaceAliasesOccurrences(secondaryLine, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        } else {
            secondaryLine = context.getUsersManager()
                    .replaceAliasesOccurrences(secondaryLine, ClientUsersManager.FindBy.NAME_ALIAS);
        }
        if(doNot == null) {
            assertThat(String.format("The current secondary line for conversation item %s is not equal to %s",
                    conversation, secondaryLine),
                    getFolderViewPage().isSecondaryLineVisible(conversation, secondaryLine));
        } else {
            assertThat(String.format("The current secondary line for conversation item %s is equal to '%s' while it should not be",
                    conversation, secondaryLine),
                    getFolderViewPage().isSecondaryLineInvisible(conversation, secondaryLine));
        }
    }

    @When("^I swipe right on conversation (.*) in Folder view")
    public void ISwipeRightOnGroupedConversation(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getFolderViewPage().swipeRightOnGroupedConversation(name);
    }

    @Then("^I see unread conversations badge is (\\d+) for folder \"(.*)\"$")
    public void ISeeUnreadConversationsCounter(int number, String folderName) {
        assertThat(String.format("The number of unread conversations is not %s for folder %s", number, folderName),
                getFolderViewPage().isBadgeCountForFolder(folderName, number));
    }

    @Then("^I do not see unread conversations badge for folder \"(.*)\"$")
    public void iDoNotSeeUnreadConversationsBadge(String folderName) {
        assertThat(String.format("There is an unread conversations badge on folder %s", folderName),
                getFolderViewPage().isBadgeCountInvisibleForFolder(folderName));
    }
}
