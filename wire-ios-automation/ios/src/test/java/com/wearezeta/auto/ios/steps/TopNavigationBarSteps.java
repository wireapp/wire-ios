package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.TopNavigationBarPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.io.IOException;

import static org.hamcrest.MatcherAssert.assertThat;

public class TopNavigationBarSteps {
    IOSTestContext context;

    public TopNavigationBarSteps(IOSTestContext context) {
        this.context = context;
    }

    private TopNavigationBarPage getTopNavigationBarPage() {
        return context.getPagesCollection()
                .getPage(TopNavigationBarPage.class);
    }

    @When("^I open Self profile$")
    public void IOpenView() {
        getTopNavigationBarPage().tapProfileButton();
    }

    @When("^I (do not )?see Self profile button on Conversations list page$")
    public void IOpenView(String doNot) {
        if(doNot == null) {
            assertThat("The Self profile button is expected to be visible but it's not",
                    getTopNavigationBarPage().isSelfProfileButtonVisible());
        } else {
            assertThat("The Self profile button is expected to be invisible but it's not",
                    getTopNavigationBarPage().isSelfProfileButtonInvisible());
        }
    }

    @Then("^I tap on my profile photo in conversation list$")
    public void iTapMyImageInConversationView() {
        getTopNavigationBarPage().tapProfileImage();
    }

    @Then("^I (do not )?see legal hold indicator next to self title in Conversation list$")
    public void iSeeLegalHoldIndicatorInConversationList(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("The legal hold indicator is not visible next to self title",
                    getTopNavigationBarPage().isLegalHoldIndicatorVisible());
        } else {
            assertThat("The legal hold indicator is visible next to self title while it should not be",
                    getTopNavigationBarPage().isLegalHoldIndicatorInvisible());
        }
    }

    @Then("^I tap the legal hold indicator next to self title in Conversation list$")
    public void iTapLegalHoldIndicatorInConversationList() {
        getTopNavigationBarPage().iTapLegalHoldIndicator();
    }

    @When("^I open search screen")
    public void iOpenSearchScreen() {
        getTopNavigationBarPage().iOpenSearchScreen();
    }
    @When("^I opened the filters")
    public void iTapFilterButton() {
        getTopNavigationBarPage().iTapOnFilterButton();
    }
}