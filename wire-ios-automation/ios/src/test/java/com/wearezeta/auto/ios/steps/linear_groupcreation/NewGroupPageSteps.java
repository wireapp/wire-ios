package com.wearezeta.auto.ios.steps.linear_groupcreation;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.linear_groupcreation.NewGroupPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class NewGroupPageSteps {
    IOSTestContext context;

    public NewGroupPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private NewGroupPage getNewGroupPage() {
        return context.getPagesCollection().getPage(NewGroupPage.class);
    }

    @When("^I enter group name \"(.*)\" on New Group page$")
    public void iEnterGroupnameOnNewGroupPage(String groupName) {
        getNewGroupPage().enterGroupName(groupName);
    }

    @When("^I tap Next button on New Group page$")
    public void iTapNextButtonOnNewGroupPage() {
        getNewGroupPage().tapNextButton();
    }

    @When("^I (?:expand|collapse) conversation options on New Group page$")
    public void iChangeStateOfConversationOptions() {
        getNewGroupPage().tapConversationOptions();
    }

    @When("^I verify the value of Allow Guests equals to \"(.*)\" on New Group page")
    public void iVerifyAllowGuestValue(String expectedValue) {
        assertThat(String.format("The value of Allow Guests is not equal to '%s'", expectedValue),
                getNewGroupPage().isAllowGuestsEqualsTo(expectedValue));
    }

    @When("^I switch Allow Guests toggle on New Group page$")
    public void iSwitchAllowGuestsToggle() {
        getNewGroupPage().switchToggle();
    }

    @When("^I see the summary value of Conversation Options \"(.*)\" on New Group page")
    public void iVerifyDefaultConversationOptionsValue(String options) {
        assertThat(
                String.format("Expected conversation options not visible '%s'", options),
                getNewGroupPage().isExpectedConversationOptionsVisible(options));
    }

    @Then("^I (do not )?see Protocol option on New Group page$")
    public void seeProtocol(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Protocol option should be visible",
                getNewGroupPage().isProtocolVisible());
        } else {
            assertThat("Protocol option should not be visible",
                getNewGroupPage().isProtocolInvisible());
        }
    }

    @Then("^I (do not )?see Proteus value in Protocol option on New Group page$")
    public void seeProteusProtocol(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Proteus value should be visible",
                getNewGroupPage().isProteusValueVisible());
        } else {
            assertThat("Proteus value should not be visible",
                getNewGroupPage().isProteusValueInvisible());
        }
    }

    @Then("^I (do not )?see MLS value in Protocol option on New Group page$")
    public void seeMlsProtocol(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("MLS value should be visible",
                    getNewGroupPage().isMlsValueVisible());
        } else {
            assertThat("MLS value should not be visible",
                    getNewGroupPage().isMlsValueInvisible());
        }
    }

    @When("^I tap Protocol option on New Group page$")
    public void iTapProtocolOption() {
        getNewGroupPage().tapProtocolOption();
    }

    @When("^I tap MLS option on New Group page$")
    public void iTapMlsOption() {
        getNewGroupPage().tapMlsOption();
    }

    @Then("^I see max (\\d+) participant limit on New Group page$")
    public void ISeeMaxParticipantLimit(int limit) {
        assertThat(String.format("Max limit '%d' is not visible", limit),
                getNewGroupPage().isMaxLimitEqualsTo(limit));
    }

    @Then("^I (do not )?see Guests option on group creation view$")
    public void ISeeGuestOption(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("'Guests option is expected to be visible",
                    getNewGroupPage().isGuestOptionVisible());
        } else {
            assertThat("Guests option is not expected to be visible",
                    getNewGroupPage().isGuestOptionInvisible());
        }
    }

    @Then("^I (do not )?see Services option on group creation view$")
    public void ISeeServiceOption(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("'Services option is expected to be visible",
                    getNewGroupPage().isServiceOptionVisible());
        } else {
            assertThat("Services option is not expected to be visible",
                    getNewGroupPage().isServiceOptionInvisible());
        }
    }
}
