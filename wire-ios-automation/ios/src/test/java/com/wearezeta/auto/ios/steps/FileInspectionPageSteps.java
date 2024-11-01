package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.FileInspectionPage;
import io.cucumber.java.en.When;

public class FileInspectionPageSteps {
    IOSTestContext context;

    public FileInspectionPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private FileInspectionPage getPage()  {
        return context.getPagesCollection().getPage(FileInspectionPage.class);
    }

    @When("^I tap Share button in file inspection page$")
    public void iTapShareButtonInFileInspectionPage() {
        getPage().tapShareButton();
    }

    @When("^I tap Done button in file inspection page$")
    public void iTapDoneButtonInFileInspectionPage() {
        getPage().tapDoneButton();
    }
}
