package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.KeyboardGalleryPage;

import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class KeyboardGalleryPageSteps {
    IOSTestContext context;

    public KeyboardGalleryPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private KeyboardGalleryPage getKeyboardGalleryPage()  {
        return context.getPagesCollection().getPage(KeyboardGalleryPage.class);
    }

    /**
     * Tap the first visible picture on Keyboard Gallery overlay
     */
    @When("^I select the first item from Keyboard Gallery$")
    public void ISelectFirstPicture()  {
        getKeyboardGalleryPage().selectFirstPicture();
    }

    @When("^I tap Camera Roll button on Keyboard Gallery overlay$")
    public void ITapCameraRollButton()  {
        getKeyboardGalleryPage().tapCameraRollButton();
    }

    @When("^I tap Fullscreen Camera button on Keyboard Gallery overlay$")
    public void ITapFullscreenCameraButton()  {
        getKeyboardGalleryPage().tapFullScreenButton();
    }

    @When("^I (do not )?see first item from Keyboard Gallery$")
    public void iSeeFirstItemGallery(String shouldNot) {
        if (shouldNot == null) {
            assertThat("Firt item from Keyboard Gallery is not visible",
                    getKeyboardGalleryPage().isFirstItemGalleryVisible());
        } else {
            assertThat("Firt item from Keyboard Gallery is visible",
                    getKeyboardGalleryPage().isFirstItemGalleryInvisible());
        }
    }
}
