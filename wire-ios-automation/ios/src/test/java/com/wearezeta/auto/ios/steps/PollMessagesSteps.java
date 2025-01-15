package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.PollMessagesPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class PollMessagesSteps {

    IOSTestContext context;

    public PollMessagesSteps(IOSTestContext context) {
        this.context = context;
    }

    private PollMessagesPage getPollMessagesPage() {
        return context.getPagesCollection().getPage(PollMessagesPage.class);
    }

    @Then("^I see the poll message contains text \"([^\"]*)\"$")
    public void iSeeThePollMessageContainsText(String text) {
        assertThat("Poll message text is incorrect.", getPollMessagesPage().isPollMessageTextContains(text));
    }

    @Then("^I see all the poll buttons are in unselected state$")
    public void iSeeAllThePollButtonsAreInUnselectedState() {
        assertThat("All poll buttons are not in unselected mode.", getPollMessagesPage().areAllPollButtonsUnselected());
    }

    @When("^I tap poll button with the text \"([^\"]*)\"$")
    public void iTapPollButtonWithTheText(String text) {
        getPollMessagesPage().tapPollButtonWithTheText(text);
    }

    @Then("^I see the poll button with the text \"([^\"]*)\" is Confirmed$")
    public void iSeeThePollButtonWithTheTextIsSelected(String buttonText) {
        assertThat("State of the poll button with text \"" + buttonText + "\" is not confirmed.", getPollMessagesPage().isPollButtonWithTextConfirmed(buttonText));
    }

    @Then("^I see the poll button with the text \"([^\"]*)\" is Unselected$")
    public void iSeeThePollButtonWithTheTextIsUnselected(String buttonText) {
        assertThat("State of the poll button with text \"" + buttonText + "\" is selected but it should not be.", getPollMessagesPage().isPollButtonWithTextUnselected(buttonText));

    }

    @Then("^I see the poll button with the text \"([^\"]*)\" is Selected$")
    public void iSeeThePollButtonWithTheTextIsLoading(String buttonText) {
        assertThat("State of the poll button with text \"" + buttonText + "\" is not selected.", getPollMessagesPage().isPollButtonWithTextSelected(buttonText));
    }


    @Then("^I (do not )?see error contains \"(.*)\" under the poll button$")
    public void iSeeErrorUnderButtonInPollMessage(String shouldNotSee, String error) {
        if (shouldNotSee == null) {
            assertThat("Wrong error message is \" + error + \" + not visible",
                    getPollMessagesPage().isPollErrorMessageVisible(error));
        } else {
            assertThat("Wrong error message is \" + error + \" + not visible",
                    getPollMessagesPage().isPollErrorMessageInvisible(error));
        }
    }
}
