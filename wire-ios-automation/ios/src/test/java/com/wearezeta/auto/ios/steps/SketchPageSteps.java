package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.SketchPage;

import io.cucumber.java.en.When;

public class SketchPageSteps {
    IOSTestContext context;

    public SketchPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private SketchPage getSketchPage()  {
        return context.getPagesCollection()
                .getPage(SketchPage.class);
    }

    /**
     * randomly draws lines in sketch feature
     */
    @When("^I draw a random sketch$")
    public void IDrawRandomSketches()  {
        getSketchPage().sketchRandomLines();
    }

    @When("^I tap Send button on Sketch page$")
    public void ITapSendButton()  {
        getSketchPage().tapSendButton();
    }
}
