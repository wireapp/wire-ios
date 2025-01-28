package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.CameraRollPage;
import io.cucumber.java.en.When;

public class CameraRollPageSteps {

    IOSTestContext context;

    public CameraRollPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CameraRollPage getCameraRollPage()  {
        return context.getPagesCollection().getPage(CameraRollPage.class);
    }

    @When("^I select a picture from Camera Roll$")
    public void ISelectPicture()  {
        getCameraRollPage().selectPicture();
    }

    @When("^I select first picture from Camera Roll$")
    public void ISelectFirstPicture()  {
        getCameraRollPage().selectFirstPicture();
    }
}
