package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.PasteDialog;
import io.cucumber.java.en.When;

public class PasteDialogSteps {

    private IOSTestContext context;

    public PasteDialogSteps(IOSTestContext context) {
        this.context = context;
    }

    @When("I tap OK button on paste dialog")
    public void iTapOKButton() {
        context.getPagesCollection().getPage(PasteDialog.class).tapOKButton();
    }

}
