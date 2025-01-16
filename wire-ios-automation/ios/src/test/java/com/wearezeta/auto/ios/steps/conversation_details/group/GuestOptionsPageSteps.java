package com.wearezeta.auto.ios.steps.conversation_details.group;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.details_overlay.group.GuestOptionsPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class GuestOptionsPageSteps {
    IOSTestContext context;

    public GuestOptionsPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GuestOptionsPage getPage() {
        return context.getPagesCollection().getPage(GuestOptionsPage.class);
    }

    /**
     * Verify the current value of a toggle Allow Guests
     */
    @When("^I verify the value of Allow Guests equals to \"(.*)\" on Guest Options page")
    public void iVerifyAllowGuestValue(String expectedValue) {
        assertThat(String.format("The value of Allow Guests is not equal to '%s'", expectedValue),
                getPage().isAllowGuestsEqualsTo(expectedValue));
    }

    @When("^I tap Back button on Guest Options page$")
    public void iTapBackButtonOnGuestOptionsPage(){
        getPage().tapBackButton();
    }

    @Then("^I (do not )?see Create Link button on Guest Options page$")
    public void iSeeCreateLinkButton(String shouldNotBeVisible){
        if (shouldNotBeVisible == null) {
            assertThat("'Create Link' button should be visible",
                    getPage().isCreateLinkButtonVisible());
        } else {
            assertThat("'Create Link' button should be invisible",
                    getPage().isCreateLinkButtonInvisible());
        }
    }
}
