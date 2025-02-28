package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.VoiceFiltersOverlay;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import static org.hamcrest.MatcherAssert.assertThat;

public class VoiceFiltersOverlaySteps {
    IOSTestContext context;

    public VoiceFiltersOverlaySteps(IOSTestContext context) {
        this.context = context;
    }

    private VoiceFiltersOverlay getVoiceFiltersOverlay()  {
        return context.getPagesCollection().getPage(VoiceFiltersOverlay.class);
    }

    @When("^I tap Start Recording button on Voice Filters overlay$")
    public void ITapOnStartButton()  {
        getVoiceFiltersOverlay().tapOnStartButton();
    }

    @When("^I tap Stop Recording button on Voice Filters overlay$")
    public void ITapOnStopButton()  {
        getVoiceFiltersOverlay().tapOnStopButton();
    }

    @When("^I tap Confirm button on Voice Filters overlay$")
    public void ITapOnConfirmButton()  {
        getVoiceFiltersOverlay().tapOnConfirmButton();
    }

    @When("^I tap (\\d+) random effect buttons? on Voice Filters overlay$")
    public void ITapXRandomEffectButtons(int count)  {
        getVoiceFiltersOverlay().tapRandomEffectButtons(count);
    }

    @Then("^I (do not )?see Confirm button on Voice Filters overlay$")
    public void ISeeConfirmButton(String shouldNotSee)  {
        if (shouldNotSee == null) {
            assertThat(("The confirm recording button is not visible on Voice Filters overlay"), getVoiceFiltersOverlay().isConfirmButtonVisible());
        } else {
            assertThat(("The confirm recording button is visible on Voice Filters overlay, but should be hidden"), getVoiceFiltersOverlay().isConfirmButtonInVisible());
        }
    }
}