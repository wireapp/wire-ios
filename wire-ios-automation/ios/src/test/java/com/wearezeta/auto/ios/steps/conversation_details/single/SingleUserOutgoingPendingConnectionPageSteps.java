package com.wearezeta.auto.ios.steps.conversation_details.single;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Then;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.ios.pages.details_overlay.single.SinglePendingUserOutgoingConnectionPage;

import io.cucumber.java.en.When;

public class SingleUserOutgoingPendingConnectionPageSteps {
    IOSTestContext context;

    public SingleUserOutgoingPendingConnectionPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SinglePendingUserOutgoingConnectionPage getPage()  {
        return context.getPagesCollection().getPage(SinglePendingUserOutgoingConnectionPage.class);
    }

    /**
     * Verify user details presence on Single user Pending outgoing connection page
     *
     * @param shouldNotSee equals to null if the label should be visible
     * @param value        the actual value or alias
     * @param fieldType    either unique username or Address Book name or name
     */
    @Then("^I (do not )?see (unique username|Address Book name|name|common friends count) (\".*\" |\\s*)on Single user Pending outgoing connection page$")
    public void ISeeLabel(String shouldNotSee, String fieldType, String value)  {
        value = context.getUsersManager()
                .replaceAliasesOccurrences(value, ClientUsersManager.FindBy.NAME_ALIAS,
                        ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        if (shouldNotSee == null) {
            if (value.startsWith("\"")) {
                value = value.trim().replaceAll("^\"|\"$", "");
                assertThat(String.format("'%s' field is expected to be visible", value),
                        getPage().isUserDetailVisible(fieldType, value));
            } else {
                assertThat(String.format("'%s' field is expected to be visible", fieldType),
                        getPage().isUserDetailVisible(fieldType));
            }
        } else {
            if (value.startsWith("\"")) {
                value = value.trim().replaceAll("^\"|\"$", "");
                assertThat(String.format("'%s' field is expected to be invisible", value),
                        getPage().isUserDetailInvisible(fieldType, value));
            } else {
                assertThat(String.format("'%s' field is expected to be invisible", fieldType),
                        getPage().isUserDetailInvisible(fieldType));
            }
        }
    }

    /**
     * Verify button visibility on Single user Pending outgoing connection page
     *
     * @param shouldNotSee equals to null if the button should be visible
     * @param btnName      button name
     */
    @Then("^I (do not )?see (Connect) button on Single user Pending outgoing connection page$")
    public void ISeeConnectButton(String shouldNotSee, String btnName)  {
        if (shouldNotSee == null) {
            assertThat(String.format("'%s' button is expected to be visible", btnName),
                    getPage().isButtonVisible(btnName));
        } else {
            assertThat(String.format("'%s' button is expected to be invisible", btnName),
                    getPage().isButtonInvisible(btnName));
        }
    }

    @Then("^I (do not )?see Cancel Request button on Single user Pending outgoing connection page$")
    public void ISeeCancelRequestButton(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat("Cancel Request button is expected to be visible",
                    getPage().isCancelRequestButtonVisible());
        } else {
            assertThat("'%s' button is expected to be invisible",
                    getPage().isCancelRequestButtonInvisible());
        }
    }

    /**
     * Tap the corresponding button on Single user Pending incoming connection page
     *
     * @param btnName button name
     */
    @When("^I tap (Cancel Request|Archive|Connect|X) button on Single user Pending outgoing connection page$")
    public void ITapButton(String btnName)  {
        getPage().tapButton(btnName);
    }

    @When("^I tap Back button on Single user Pending outgoing connection page$")
    public void ITapBackButton()  {
        getPage().tapBackButton();
    }

    @When("^I tap Back button on Single user Pending outgoing connection page on iPad$")
    public void ITapBackButtoniPad()  {
        getPage().tapBackButtoniPad();
    }
}
