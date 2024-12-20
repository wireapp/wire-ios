package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.StatusActionSheetPage;
import io.cucumber.java.en.Then;

public class StatusActionSheetSteps {
    IOSTestContext context;

    public StatusActionSheetSteps(IOSTestContext context) {
        this.context = context;
    }

    private StatusActionSheetPage getStatusActionSheetPage() {
        return context.getPagesCollection()
                .getPage(StatusActionSheetPage.class);
    }

    /**
     * I tap the status that I want to set my profile to
     *
     * @param statusName the name of the status that I want (None, Available, Busy or Away)
     */
    @Then("^I tap status (None|Available|Busy|Away)$")
    public void iTapMyNameInConversationView(String statusName) {
        getStatusActionSheetPage().tapStatusName(statusName);
    }
}
