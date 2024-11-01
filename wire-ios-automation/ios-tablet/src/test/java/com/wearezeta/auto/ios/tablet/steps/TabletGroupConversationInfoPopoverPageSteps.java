package com.wearezeta.auto.ios.tablet.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.tablet.pages.TabletGroupConversationInfoPopoverPage;

import io.cucumber.java.en.When;

public class TabletGroupConversationInfoPopoverPageSteps {

    private IOSTestContext context;

    public TabletGroupConversationInfoPopoverPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private TabletGroupConversationInfoPopoverPage getTabletGroupConversationDetailPopoverPage() {
        return context.getPagesCollection().getPage(TabletGroupConversationInfoPopoverPage.class);
    }

    /**
     * Tap on the screen to dismiss popover
     */
    @When("^I dismiss popover on iPad$")
    public void IDismissPopover() {
        getTabletGroupConversationDetailPopoverPage().dismissPopover();
    }
}
