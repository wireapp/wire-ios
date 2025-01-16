package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ConversationViewPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import com.wearezeta.auto.ios.pages.search.MentionSuggestionsList;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;

public class MentionSteps {
    IOSTestContext context;

    public MentionSteps(IOSTestContext context) {
        this.context = context;
    }

    private MentionSuggestionsList getSuggestedMentionsList()  {
        return context.getPagesCollection().getPage(MentionSuggestionsList.class);
    }

    private ConversationViewPage getConversationViewPage()  {
        return context.getPagesCollection().getPage(ConversationViewPage.class);
    }

    /**
     * Tap on the suggested mention with name x
     *
     * @param name the name of the suggested mention that should be tapped
     */
    @When("^I tap (.*) in the suggested mentions list$")
    public void ITapSuggestedMentions(String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getSuggestedMentionsList().tapSuggestedMention(name);
    }

    /**
     * Checks if the last message contains mentions
     *
     * @param doesNot equals to null if message should contain mention
     * @param names The names of the users that should be mentioned
     */
    @Then("^I see the last message in the conversation view (does not )?contains? mentions? (.*)$")
    public void messageContainsMentions(String doesNot, String names) {
        for (String name : context.getUsersManager().splitAliases(names)) {
            name = context.getUsersManager()
                    .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
            if(doesNot == null) {
                assertThat(
                        String.format("The last message in the conversation does not contain the expected mention @%s",
                                name), getSuggestedMentionsList().isRecentMention(name));
            } else {
                assertThat(
                        String.format("The last message in the conversation contains the mention @'%s' while this is not expected",
                                name), getSuggestedMentionsList().isNotRecentMention(name));
            }
        }
    }

    /**
     * Checks for icon in the suggestion list
     *
     * @param iconName the expected icon
     * @param name the name of the user that has the icon
     */
    @Then("^I see the (verified|guest|external) icon in the suggestions list for user (.*)$")
    public void iSeeIconInSuggestionsList(String iconName, String name) {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        switch (iconName.toLowerCase()) {
            case "verified":
                assertThat(String.format("The verified icon is not visible for user '%s' in the suggested mentions list",
                        name), getSuggestedMentionsList().isVerifiedLabelVisibleFor(name));
                break;
            case "guest":
                assertThat(String.format("The guest icon is not visible for user '%s' in the suggested mentions list",
                        name), getSuggestedMentionsList().isGuestLabelVisibleFor(name));
                break;
            case "external":
                assertThat(String.format("The external icon is not visible for user '%s' in the suggested mentions list",
                        name), getSuggestedMentionsList().isExternalLabelVisibleFor(name));
                break;
            default:
                throw new IllegalArgumentException(String.format("Unknown view type: %s", iconName));
        }
    }

    /**
     * Check if the suggestion list is visible
     * @param doNotSee whether or not the suggestion list should be visible
     */
    @Then("^I (do not )?see the suggested mentions list$")
    public void iSeeTheSuggestedMentionsList(String doNotSee)  {
        if (doNotSee == null) {
            assertThat("Suggestion list is invisble while this is not expected", getSuggestedMentionsList().isSuggestionsVisible());
        } else {
            assertThat("Suggestion list is visbile while this is not expected", !getSuggestedMentionsList().isSuggestionsVisible());
        }
    }
}
