package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Then;
import static org.hamcrest.MatcherAssert.assertThat;

import com.wearezeta.auto.ios.pages.VideoPlayerPage;

import io.cucumber.java.en.When;

public class VideoPlayerPageSteps {
	IOSTestContext context;

	public VideoPlayerPageSteps(IOSTestContext context) {
		this.context = context;
	}

	private VideoPlayerPage getVideoPlayerPage()  {
		return context.getPagesCollection().getPage(VideoPlayerPage.class);
	}

	@When("I see the video player web page is opened")
	public void ISeeVideoPlayerWebPage()  {
		assertThat("Video Player web page is not opened", getVideoPlayerPage().isVideoPlayerPageOpened());
	}

	@Then("^I see pause button on Video page$")
	public void ISeePauseButton()  {
		assertThat("Pause button is not displayed", getVideoPlayerPage().
				isPlayPauseButtonVisible());
	}

	@When("^I tap Done button on video message player page$")
	public void ITapDoneButtonOnVideoMessagePlayer()  {
		getVideoPlayerPage().tapDoneButton();
	}
}
