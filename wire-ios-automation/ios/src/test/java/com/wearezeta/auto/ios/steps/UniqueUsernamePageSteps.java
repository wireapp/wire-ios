package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.UniqueUsernamePage;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class UniqueUsernamePageSteps {
    IOSTestContext context;

    public UniqueUsernamePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private UniqueUsernamePage getUniqueUsernamePage()  {
        return context.getPagesCollection().getPage(UniqueUsernamePage.class);
    }

    @When("^I tap Save button on Unique Username page$")
    public void ITapButtonOnUniqueUsernamePage()  {
        getUniqueUsernamePage().tapSaveButton();
    }

    /**
     * Fill in name input an string
     *
     * @param name string to be input
     */
    @When("^I enter \"(.*)\" name on Unique Username page$")
    public void IFillInNameInInputOnUniqueUsernamePage(String name)  {
        name = context.getUsersManager()
                .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);
        getUniqueUsernamePage().inputStringInNameInput(name);
    }

    /**
     * Verify Save button isEnable state
     *
     * @param expectedState Disabe/Enable
     */
    @When("^I see Save button state is (Disabled|Enabled) on Unique Username page$")
    public void ISeeSaveButtonIsDisabled(String expectedState)  {
        boolean buttonState = getUniqueUsernamePage().isSaveButtonEnabled();
        if (expectedState.equals("Disabled")) {
            assertThat(String.format("Wrong Save button state. Should be %s.", expectedState), !buttonState);
        } else {
            assertThat(String.format("Wrong Save button state. Should be %s.", expectedState), buttonState);
        }
    }
}
