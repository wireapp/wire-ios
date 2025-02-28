package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.ios.pages.GiphyPreviewPage;

import io.cucumber.java.en.When;

public class GiphyPreviewPageSteps {
    IOSTestContext context;

    public GiphyPreviewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private GiphyPreviewPage getGiphyPreviewPage()  {
        return context.getPagesCollection()
                .getPage(GiphyPreviewPage.class);
    }

    @When("^I select the first item from Giphy grid$")
    public void ISelectFirstItem()  {
        getGiphyPreviewPage().selectFirstItem();
    }

    @When("^I tap Send button on Giphy preview page$")
    public void ITapSendButtonOnGiphyPreview()  {
        getGiphyPreviewPage().tapSendButton();
    }

    @When("^I see Giphy preview page$")
    public void ISeeGiphyPreviewPage()  {
        assertThat("Giphy Send Button is not visible", getGiphyPreviewPage().isSendButtonVisible());
        assertThat("Giphy Cancel Button is not visible", getGiphyPreviewPage().isCancelButtonVisible());
    }

    @When("^I see Giphy grid preview$")
    public void ISeeGiphyGridPreview()  {
        assertThat("Giphy grid is not shown", getGiphyPreviewPage().isGridVisible());
    }
}