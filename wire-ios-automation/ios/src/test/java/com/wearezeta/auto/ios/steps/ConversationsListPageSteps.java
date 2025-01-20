package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager.FindBy;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ConversationsListPage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;
import java.util.regex.Pattern;

public class ConversationsListPageSteps {

    IOSTestContext context;

    public ConversationsListPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ConversationsListPage getConversationsListPage() {
        return context.getPagesCollection()
                .getPage(ConversationsListPage.class);
    }

    @Given("^I (do not )?see conversations list$")
    public void GivenISeeConversationsList(String doNot) {
        if (doNot == null) {
            assertThat("Conversations list is not visible after the timeout",
                    getConversationsListPage().isVisible());
        } else {
            assertThat("Conversations list is visible while it should not be",
                    getConversationsListPage().isInvisible());
        }
    }

    /**
     * Open the corresponding conversation by tapping its name in the conversations list
     *
     * @param name conversation name/alias
     */
    @Given("^I open (?:group |single |1:1 |\\s?)conversation \"(.*)\" in conversation list")
    public void IOpenRecentConversation(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, FindBy.NAME_ALIAS);
        getConversationsListPage().tapConversationItemRecentList(name);
    }

    @When("I long tap conversation '(.*)' in conversation list")
    public void iLongTapConversationVInConversationList(String conversationName) {
        getConversationsListPage().longTapConversationItemRecentList(conversationName);
    }

    @When("I long tap alias conversation '(.*)' in conversation list")
    public void iLongTapAliasConversationVInConversationList(String alias) {
        String name = context.getUsersManager().findUserByNameOrNameAlias(alias).getName();
        getConversationsListPage().longTapConversationItemRecentList(name);
    }

    @When("I long tap 1:1 conversation '(.*)' in conversation list")
    public void iLongTap11ConversationVInConversationList(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, FindBy.NAME_ALIAS);
        getConversationsListPage().longTapConversationItemRecentList(name);
    }

    private final static Timedelta CONVO_LIST_UPDATE_TIMEOUT = Timedelta.ofSeconds(10);

    /**
     * Verify whether the first items in conversations list is the given item
     *
     * @param convoName conversation name
     */
    @Then("^I see the name of the first conversation is (.*)")
    public void ISeeUserNameFirstInContactList(String convoName) {
        final String name = context.getUsersManager()
                .replaceAliasesOccurrences(convoName, FindBy.NAME_ALIAS);
        assertThat(String.format("The conversation '%s' is not the first conversation in the list after " +
                        "%s timeout", name, CONVO_LIST_UPDATE_TIMEOUT),
                CommonUtils.waitUntilTrue(CONVO_LIST_UPDATE_TIMEOUT, Timedelta.ofSeconds(1),
                        () -> getConversationsListPage().isFirstConversationName(name))
        );
    }

    @Then("^I see conversation (.*) in conversations list$")
    public void iSeeUserInContactList(String value) {
        value = context.getUsersManager().replaceAliasesOccurrences(value, FindBy.NAME_ALIAS);
        assertThat(String.format("The conversation '%s' is not visible in the conversation list",
                value), getConversationsListPage().isConversationInList(value));
    }

    @Then("^I do not see conversation (.*) in conversations list$")
    public void iDoNotSeeUserInContactList(String value) {
        value = context.getUsersManager().replaceAliasesOccurrences(value, FindBy.NAME_ALIAS);
        assertThat(
                String.format("The conversation '%s' is visible in the conversation list, but should be hidden",
                        value), getConversationsListPage().isConversationNotInList(value));
    }

    @When("^I swipe right on conversation (.*) in Conversations view")
    public void ISwipeRightOnConversationInConvView(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, FindBy.NAME_ALIAS);
        getConversationsListPage().swipeRightOnConversation(name);
    }

    /**
     * Verify visibility of EVERYTHING ARCHIVED placeholder message in conversation list
     */
    @Then("^I see EVERYTHING ARCHIVED placeholder in conversations list$")
    public void ISeeNoConversationMessage() {
        assertThat("'EVERYTHING ARCHIVED' placeholder is not visible",
                getConversationsListPage().isConversationsListPlaceholderVisible());
    }

    @When("^I tap JOIN button in conversations list next to (.*)")
    public void ITapButtonInContactListNextTo(String contact) {
        final String name = context.getUsersManager().replaceAliasesOccurrences(contact, FindBy.NAME_ALIAS);
        getConversationsListPage().tapJoinButtonNextTo(name);
    }

    @When("I tap Incoming Pending Requests item in conversations list")
    public void ITapPendingRequestLinkContactList() {
        getConversationsListPage().tapPendingRequest();
    }

    @When("I (do not )?see Pending request link in conversations list$")
    public void ISeePendingRequestLinkInContacts(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Pending request link is not in conversations list",
                    getConversationsListPage().isPendingRequestInContactList());
        } else {
            assertThat("Pending request link is shown in conversations list",
                    getConversationsListPage().pendingRequestInContactListIsNotShown());
        }
    }

    /**
     * Check value of status icon in conversation list
     *
     * @param status       the number of unread messages in the status icon
     * @param conversation the unread messages are in
     */
    @Then("^I see status of conversations list item (.*) is (not )?\"(.*)\"$")
    public void ISeeConversationStatus(String conversation, String notChanged, String status) {
        conversation = context.getUsersManager()
                .replaceAliasesOccurrences(conversation, ClientUsersManager.FindBy.NAME_ALIAS);
        status = context.getUsersManager().replaceAliasesOccurrences(status, FindBy.NAME_ALIAS);
        if (notChanged == null) {
            assertThat(String.format("The current status for conversation item %s is not equal to %s",
                    conversation, status),
                    getConversationsListPage().isConversationItemWithStatusVisible(status, conversation));
        } else {
            assertThat(String.format("The current status for conversation item %s is not expected to be equal " +
                            "to %s",
                    conversation, status),
                    getConversationsListPage().isConversationItemWithStatusInvisible(status, conversation));
        }
    }

    /**
     * Check the secondary line of the conversation item in conversation list
     *
     * @param secondaryLine     the text of the secondary line
     * @param conversation      the secondary line belongs to
     */
    @Then("^I see the secondary line in conversations list item (.*) is \"(.*)\"$")
    public void ISeeTheSecondaryIs(String conversation, String secondaryLine) {
        conversation = context.getUsersManager()
                .replaceAliasesOccurrences(conversation, ClientUsersManager.FindBy.NAME_ALIAS);
        final Pattern usernamePattern = Pattern.compile(ClientUsersManager.
                STR_UNIQUE_USERNAME_ALIAS_TEMPLATE.apply("\\d+"));
        if (usernamePattern.matcher(secondaryLine).find()) {
            secondaryLine = context.getUsersManager()
                    .replaceAliasesOccurrences(secondaryLine, FindBy.UNIQUE_USERNAME_ALIAS);
        } else {
            secondaryLine = context.getUsersManager()
                    .replaceAliasesOccurrences(secondaryLine, ClientUsersManager.FindBy.NAME_ALIAS);
        }
        assertThat(String.format("The current secondary line for conversation item %s is not equal to %s",
                conversation, secondaryLine),
                getConversationsListPage().isSecondaryLineVisible(conversation, secondaryLine));
    }

    /**
     * Check that the conversation item in conversation list has no status set
     *
     * @param isNot        equals to null if a status should be visible
     * @param conversation list item to check status of
     */
    @Given("^I (do not )?see a status for conversations list item (.*)$")
    public void IDoNotSeeAConversationStatusForContact(String isNot, String conversation) {
        conversation = context.getUsersManager()
                .replaceAliasesOccurrences(conversation, ClientUsersManager.FindBy.NAME_ALIAS);
        if (isNot == null) {
            assertThat(String.format("The status for conversation item %s is not set", conversation),
                    getConversationsListPage().isConversationItemStatusVisible(conversation));
        } else {
            assertThat(String.format("The status for conversation item %s is set", conversation),
                    getConversationsListPage().isConversationItemStatusInvisible(conversation));
        }
    }

    @Then("^I (do not )?see classified domain icon on the outgoing connection page$")
    public void iSeeClassifiedDomainLabelOutgoingConnection(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The classified domain label should be visible on the outgoing connection page",
                    getConversationsListPage().isClassifiedLabelVisible());
        } else {
            assertThat("The classified domain label should be invisible on the outgoing connection page",
                    getConversationsListPage().isClassifiedLabelInvisible());
        }
    }

    @Then("^I (do not )?see classified domain icon on the incoming connection page$")
    public void iSeeClassifiedDomainLabelIncomingConnection(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The classified domain label should be visible on the incoming connection page",
                    getConversationsListPage().isClassifiedLabelVisible());
        } else {
            assertThat("The classified domain label should be invisible on the incoming connection page",
                    getConversationsListPage().isClassifiedLabelInvisible());
        }
    }

    @Then("^I (do not )?see unclassified domain icon on the incoming connection page$")
    public void iSeeNotClassifiedDomainLabelIncomingConnection(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The unclassified domain label should be visible on the incoming connection page",
                    getConversationsListPage().isNotClassifiedLabelVisible());
        } else {
            assertThat("The unclassified domain label should be invisible on the incoming connection page",
                    getConversationsListPage().isNotClassifiedLabelInvisible());
        }
    }

    @Then("^I (do not )?see unclassified domain icon on the outgoing connection page$")
    public void iSeeNotClassifiedDomainLabelOutgoingConnection(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The unclassified domain label should be visible on the outgoing connection page",
                    getConversationsListPage().isNotClassifiedLabelVisible());
        } else {
            assertThat("The unclassified domain label should be invisible on the outgoing connection page",
                    getConversationsListPage().isNotClassifiedLabelInvisible());
        }
    }

    @Then("^I (do not )?see classified domain label in the conversation$")
    public void iSeeClassifiedDomainLabelConvo(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The classified domain label should be visible",
                    getConversationsListPage().isClassifiedLabelVisibleConvo());
        } else {
            assertThat("The classified domain label should be invisible",
                    getConversationsListPage().isClassifiedLabelInvisibleConvo());
        }
    }

    @Then("^I (do not )?see unclassified domain label in the conversation$")
    public void iSeeNotClassifiedDomainLabelConvo(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The unclassified domain label should be visible",
                    getConversationsListPage().isNotClassifiedLabelVisibleConvo());
        } else {
            assertThat("The unclassified domain label should be invisible",
                    getConversationsListPage().isNotClassifiedLabelInvisibleConvo());
        }
    }

    @Then("^I (do not )?see classified domain label on Group participant user profile page$")
    public void iSeeClassifiedDomainLabelUserProfile(String shouldBeVisible) {
        if (shouldBeVisible == null) {
            assertThat("The classified domain label should be visible",
                    getConversationsListPage().isClassifiedLabelVisibleUserProfile());
        } else {
            assertThat("The classified domain label should be invisible",
                    getConversationsListPage().isClassifiedLabelInvisibleUserProfile());
        }
    }

    @Then("^I (do not )?see unclassified domain label on Group participant user profile page$")
    public void iSeeNotClassifiedDomainLabelUserProfile(String shouldNot) {
        if (shouldNot == null) {
            assertThat("The unclassified domain label should be visible",
                    getConversationsListPage().isNotClassifiedLabelVisibleUserProfile());
        } else {
            assertThat("The unclassified domain label should be invisible",
                    getConversationsListPage().isNotClassifiedLabelInvisibleUserProfile());
        }
    }

    @When("I choose Mark as Read from conversation list context menu")
    public void iChooseMarkAsReadFromConversationListContextMenu() {
        getConversationsListPage().tapMarkAsRead();
    }

    @When("I choose Notifications... from conversation list context menu")
    public void iChooseNotificationsFromConversationListContextMenu() {
        getConversationsListPage().tapNotificationsMenu();
    }

    @When("I choose Nothing from the Notifications submenu")
    public void iChooseNothingFromTheNotificationsSubmenu() {
        getConversationsListPage().tapNothing();
    }

    @When("I choose Archive from conversation list context menu")
    public void iChooseArchiveAsReadFromConversationListContextMenu() {
        getConversationsListPage().tapArchive();
    }

    @When("I choose Favorite from conversation list context menu")
    public void iChooseFavoriteAsReadFromConversationListContextMenu() {
        getConversationsListPage().tapFavorite();
    }

    @When("I choose Move To from conversation list context menu")
    public void iChooseMoveToFromConversationListContextMenu() {
        getConversationsListPage().tapMoveTo();
    }

    @When("I choose Clear Content from conversation list context menu")
    public void iChooseClearContentFromConversationListContextMenu() {
        getConversationsListPage().tapClearContent();
    }

    @When("I choose Block from conversation list context menu")
    public void iChooseBlockFromConversationListContextMenu() {
        getConversationsListPage().tapBlock();
    }

    @When("I choose Leave Group from conversation list context menu")
    public void iChooseLeaveGroupFromConversationListContextMenu() {
        getConversationsListPage().tapLeaveGroup();
    }

    @When("I remove conversation from favorites in conversation list context menu")
    public void iRemoveConversationFromFavoritesInConversationListContextMenu() {
        getConversationsListPage().tapRemoveFromFavorite();
    }

    @When("I choose clear from clear content menu")
    public void iChooseClearFromClearContentMenu() {
        getConversationsListPage().tapClearInClearContent();
    }

    @When("I confirm the block dialog")
    public void iConfirmTheBlockDialog() {
        getConversationsListPage().tapBlockConfirm();
    }

    @When("I choose Leave and Clear in the dialog")
    public void iChooseLeaveAndClearInTheDialog() {
        getConversationsListPage().tapLeaveAndClearConfirm();
    }

    @Then("I see that I am certified on Conversation List Page")
    public void iSeeThatIAmCertifiedOnConversationListPage() {
        assertThat("User is missing certified status", getConversationsListPage().isCertified());
    }
}

