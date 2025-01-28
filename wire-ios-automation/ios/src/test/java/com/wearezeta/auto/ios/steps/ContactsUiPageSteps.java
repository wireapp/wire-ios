package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.pages.ContactsUiPage;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class ContactsUiPageSteps {

    IOSTestContext context;

    public ContactsUiPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ContactsUiPage getContactsUiPage()  {
        return context.getPagesCollection().getPage(ContactsUiPage.class);
    }

    /**
     * Verify that ContactsUI page is shown (by verifying search input)
     */
    @When("^I see ContactsUI page$")
    public void ISeeContactsUIPage()  {
        assertThat("Search on ContactsUI page is not shown",
                getContactsUiPage().isSearchInputVisible());
        assertThat("Invite on ContactsUI page is not shown",
                getContactsUiPage().isInviteButtonVisible());
    }

    /**
     * Input user name in search field
     *
     * @param contact username
     */
    @When("^I input user name (.*) in search on ContactsUI$")
    public void IInputUserNameInSearchOnContactsUI(String contact)  {
        contact = context.getUsersManager()
                .replaceAliasesOccurrences(contact, ClientUsersManager.FindBy.NAME_ALIAS);
        getContactsUiPage().inputTextToSearch(contact);
    }

    /**
     * Verify is user is presented in ContactsUI page
     *
     * @param shouldNotBeVisible equals to null if the contact should be visible
     * @param contact            user name
     */
    @Then("^I (do not )?see contact (.*) in ContactsUI page list$")
    public void ISeeContactInContactsUIList(String shouldNotBeVisible, String contact)  {
        contact = context.getUsersManager()
                .replaceAliasesOccurrences(contact, ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotBeVisible == null) {
            assertThat(
                    String.format("User '%s' should be visible in ContactsUI user list", contact),
                    getContactsUiPage().isContactVisible(contact)
            );
        } else {
            assertThat(
                    String.format("User '%s' should not be visible in ContactsUI user list", contact),
                    getContactsUiPage().isContactInvisible(contact)
            );
        }
    }

    @When("^I tap Invite Others button on Contacts UI page$")
    public void iTapInviteOthersButton()  {
        getContactsUiPage().tapInviteOthersButton();
    }

    @When("^I tap Back button on Contacts UI page$")
    public void iTapBackButton()  {
        getContactsUiPage().tapBackButton();
    }

    /**
     * Click on Open button on ContactsUI next to user name
     *
     * @param contact user name
     */
    @When("^I tap Open button next to user name (.*) on ContactsUI$")
    public void IClickOpenButtonNextToUser(String contact)  {
        contact = context.getUsersManager()
                .replaceAliasesOccurrences(contact, ClientUsersManager.FindBy.NAME_ALIAS);
        getContactsUiPage().tapOpenButtonNextToUser(contact);
    }

}
