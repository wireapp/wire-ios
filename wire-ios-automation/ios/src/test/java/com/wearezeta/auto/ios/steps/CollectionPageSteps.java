package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.CollectionPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class CollectionPageSteps {

    IOSTestContext context;

    public CollectionPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private CollectionPage getCollectionPage() {
        return context.getPagesCollection()
                .getPage(CollectionPage.class);
    }

    @When("^I (long )?tap the item number (\\d+) in collection category PICTURES$")
    public void iTapPictureItemByIndex(String isLongTap, int index) {
        getCollectionPage().tapPictureItemByIndex(index, isLongTap != null);
    }

    @Then("^I see full-screen image preview in collection view$")
    public void iSeeFullScreenImagePreview() {
        assertThat("Full-screen image preview is expected to be visible",
                getCollectionPage().isFullScreenImagePreviewVisible());
    }

    @When("^I tap X button in collection view$")
    public void iTapCloseButton() {
        getCollectionPage().tapCloseButton();
    }
}
