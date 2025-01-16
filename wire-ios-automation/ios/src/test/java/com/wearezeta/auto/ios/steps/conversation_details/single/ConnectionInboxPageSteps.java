package com.wearezeta.auto.ios.steps.conversation_details.single;

import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Then;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.pages.details_overlay.single.ConnectionInboxPage;

import io.cucumber.java.en.When;

public class ConnectionInboxPageSteps {
    IOSTestContext context;

    public ConnectionInboxPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ConnectionInboxPage getPage()  {
        return context.getPagesCollection()
                .getPage(ConnectionInboxPage.class);
    }

    /**
     * Verify user details presence on Single user Pending incoming connection page
     *
     * @param shouldNotSee equals to null if the label should be visible
     * @param value        the actual value or alias
     * @param fieldType    either unique username or name or Address Book name
     */
    @Then("^I (do not )?see (unique username|name|Address Book name|common friends count) (\".*\" |\\s*)on Connection Inbox page$")
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

    @Then("^I see Connect button on Connection Inbox page$")
    public void iSeeConnectButton()  {
        assertThat("Button not visible", getPage().isConnectButtonVisible());
    }

    @When("^I tap Ignore button on Connection Inbox page$")
    public void iTapIgnoreButton()  {
        getPage().tapIgnoreButton();
    }

    @When("^I tap Connect button on Connection Inbox page$")
    public void iTapConnectButton()  {
        getPage().tapConnectButton();
    }
}
