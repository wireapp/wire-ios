package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.LegalHoldOverviewPage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

import java.util.List;

public class LegalHoldOverviewPageSteps {

    IOSTestContext context;

    public LegalHoldOverviewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private LegalHoldOverviewPage getLegalHoldOverviewPage()  {
        return context.getPagesCollection().getPage(LegalHoldOverviewPage.class);
    }

    @Then("^I (do not )?see Myself as a legal hold subject on Legal hold overview page$")
    public void ISeeMyselfAsLegalHoldSubject(String shouldNotSee) {
        String name = context.getUsersManager().replaceAliasesOccurrences("Myself", ClientUsersManager.FindBy.NAME_ALIAS);
        if (shouldNotSee == null) {
            assertThat(String.format("Myself should be visible as legal hold subject"), getLegalHoldOverviewPage().isMyselfVisible(name));
        } else {
            assertThat(String.format("Myself should not be visible as legal hold subject"), getLegalHoldOverviewPage().isMyselfVisible(name));
        }
    }

    @Then("^I (do not )?see legal hold subjects? (.*) on Legal hold overview page$")
    public void ISeeLegalHoldSubject(String shouldNotSee, String subjects) {
        final List<String> aliases = context.getUsersManager().splitAliases(subjects);
        for (final String alias : aliases) {
            final String name = context.getUsersManager()
                    .replaceAliasesOccurrences(alias, ClientUsersManager.FindBy.NAME_ALIAS);
            if (shouldNotSee == null) {
                assertThat(String.format("User '%s' should be visible", name), getLegalHoldOverviewPage().isSubjectDisplayNameVisible(name));
            } else {
                assertThat(String.format("User '%s' should not be visible", name), getLegalHoldOverviewPage().isSubjectDisplayNameInvisible(name));
            }
        }
    }

    @When("^I tap legal hold subject (.*) on Legal hold overview page$")
    public void iSelectSubject(String name) {
        name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
        getLegalHoldOverviewPage().tapOnSubject(name);
    }

    @When("^I tap close button legal hold overview page$")
    public void iCloseLegalHoldPage() {
        getLegalHoldOverviewPage().tapCloseButton();
    }
}
