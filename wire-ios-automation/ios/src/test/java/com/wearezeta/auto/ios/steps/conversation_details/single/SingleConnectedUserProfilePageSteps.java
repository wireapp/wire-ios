package com.wearezeta.auto.ios.steps.conversation_details.single;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.IOSPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Then;

import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.ios.pages.details_overlay.single.SingleConnectedUserProfilePage;

import io.cucumber.java.en.When;

public class SingleConnectedUserProfilePageSteps {
    IOSTestContext context;

    public SingleConnectedUserProfilePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SingleConnectedUserProfilePage getPage()  {
        return context.getPagesCollection().getPage(SingleConnectedUserProfilePage.class);
    }

    @When("^I tap Create Group button on Single user profile page$")
    public void ITapCreateGroupButton()  {
        getPage().tapCreateGroupButton();
    }

    @When("^I tap X button on Single user profile page$")
    public void ITapXButton()  {
        getPage().tapXButton();
    }

    @When("^I tap Open Menu button on Single user profile page$")
    public void ITapOpenMenuButton()  {
        getPage().tapOpenMenuButton();
    }

    @When("^I tap Back button on Single user profile page$")
    public void ITapBackButton()  {
        getPage().tapBackButton();
    }

    @When("^I switch to Devices tab on Single user profile page$")
    public void IChangeToDevicesTab()  {
        getPage().switchToDevicesTab();
    }

    @Then("^I (do not )?see Information label on Single user profile page$")
    public void ISeeInformationLabel(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("The Information label is not visible on Single user profile page",
                    getPage().isInformationLabelVisible());
        } else {
            assertThat("The Information label is still visible on Single user profile page",
                    getPage().isInformationLabelInvisible());
        }
    }

    @Then("^I see key \"(.*)\" and value \"(.*)\" at cell (\\d+) on Single user profile page$")
    public void ISeeRichProfileKeyValuePair(String key, String value, int index)  {
        assertThat("The key value pair is not visible on Single user profile page",
                getPage().isInformationKeyValuePairVisible(key, value, index));
    }

    @And("^I swipe (down|up) on Single user profile page$")
    public void iSwipe(String direction) {
        getPage().swipe(IOSPage.SwipeDirection.valueOf(direction.toUpperCase()));
    }

    @Then("^I see Read Receipt Footer on Single user profile page$")
    public void iSeeReadReceiptFooter() {
        assertThat("The read receipt footer is not visible on Single user profile page",
                getPage().isReadReceiptFooterVisible());
    }

    @When("^I tap Start Conversation button on Single user profile page$")
    public void iTapStartConversationButton() {
        getPage().tapStartConversation();
    }
}
