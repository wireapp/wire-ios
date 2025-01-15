package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.PicturePreviewPage;
import io.cucumber.java.en.When;

public class PicturePreviewPageSteps {
    IOSTestContext context;

    public PicturePreviewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private PicturePreviewPage getPicturePreviewPage()  {
        return context.getPagesCollection().getPage(PicturePreviewPage.class);
    }

    @When("^I tap Confirm button on Picture [Pp]review page$")
    public void iTapConfirmButton()  {
        getPicturePreviewPage().tapOkButton();
    }

    @When("^I tap Sketch button on Picture [Pp]review page$")
    public void ITapOnSketchButton()  {
        getPicturePreviewPage().tapSketchButton();
    }

    @When("^I tap Use Photo button on Picture [Pp]review page$")
    public void ITapOnPhotoButton()  {
        getPicturePreviewPage().tapPhotoButton();
    }

    @When("^I tap OK button on Picture [Pp]review page on iPAD$")
    public void ITapOnOkButtonOnIPad()  {
        getPicturePreviewPage().tapOkButtonOnIPad();
    }
}
