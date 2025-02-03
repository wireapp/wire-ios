package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.CameraPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class CameraPageSteps {

    IOSTestContext context;

    public CameraPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CameraPage getCameraPage() {
        return context.getPagesCollection().getPage(CameraPage.class);
    }

    @When("^I tap Take Photo button on Camera page$")
    public void iTapTakePhoto()  {
        getCameraPage().tapTakePhoto();
    }

    @When("^I tap Take Video button on Camera page$")
    public void iTapTakeVideo()  {
        getCameraPage().tapTakeVideo();
    }

    @When("^I tap Use Video button on Camera page$")
    public void iTapUseVideo()  {
        getCameraPage().tapUseVideo();
    }

    @Then("^I see Choose from library button on change profile pop up$")
    public void iSeeChooseFromLibrary()  {
        assertThat("The Choose from library button is not visible on change profile pop up",
                getCameraPage().isChooseFromLibraryVisible());
    }

    @Then("^I see Take Photo button on Camera page$")
    public void iSeePhotoButton()  {
        assertThat("The take photo button is not visible on Camera screen",
                getCameraPage().isTakePhotoButtonVisible());
    }

    @When("^I tap Choose from library button on change profile pop up$")
    public void iTapChooseFromLibrary()  {
        getCameraPage().tapChooseFromLibrary();
    }

}
