package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.BackupPasswordOverlayPage;
import io.cucumber.java.en.And;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class BackupPasswordOverlaySteps {

    IOSTestContext context;

    public BackupPasswordOverlaySteps(IOSTestContext context) {
        this.context = context;
    }

    private BackupPasswordOverlayPage getPage() {
        return context.getPagesCollection().getPage(BackupPasswordOverlayPage.class);
    }

    /**
     * Tap the corresponding button
     *
     */
    @When("^I tap Next button on Backup password overlay$")
    public void iTapNextButtonBackupOverlay() {
        getPage().tapNextButton();
    }

    /**
     * Type the given backup password
     *
     * @param password the actual password value
     */
    @And("^I type password \"(.*)\" on Backup password overlay$")
    public void iTypeBackupPassword(String password) {
        getPage().typePassword(password);
    }
}