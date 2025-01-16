package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.ImageUtil;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ImageFullScreenPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class ImageFullScreenPageSteps {
    IOSTestContext context;

    public ImageFullScreenPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private ImageFullScreenPage getImageFullScreenPage()  {
        return context.getPagesCollection().getPage(ImageFullScreenPage.class);
    }

    @When("^I see Full Screen Page opened$")
    public void ISeeFullScreenPage()  {
        assertThat("Image not in full screen",
                getImageFullScreenPage().isImageFullScreenShown());
    }

    private static final double MAX_SIMILARITY_THRESHOLD = 0.995;

    @Then("^I see the picture on image fullscreen page is animated$")
    public void ISeePictureIsAnimated()  {
        final int maxFrames = 4;
        final double avgThreshold = ImageUtil.getAnimationThreshold(getImageFullScreenPage()::getPreviewPictureScreenshot,
                maxFrames, Timedelta.ofMillis(10));
        assertThat(String.format("The picture in the image preview view seems to be static (%f >= %f)",
                avgThreshold, MAX_SIMILARITY_THRESHOLD), avgThreshold < MAX_SIMILARITY_THRESHOLD);
    }

    @When("^I tap X button on fullscreen image$")
    public void ITapXOnButtonFullscreen()  {
        getImageFullScreenPage().tapFullScreenCloseButton();
    }
}
