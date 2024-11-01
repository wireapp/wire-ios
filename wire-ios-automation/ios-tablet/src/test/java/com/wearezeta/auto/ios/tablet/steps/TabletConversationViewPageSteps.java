package com.wearezeta.auto.ios.tablet.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.tablet.pages.TabletConversationViewPage;

import io.cucumber.java.en.When;

public class TabletConversationViewPageSteps {

    private IOSTestContext context;

    public TabletConversationViewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private TabletConversationViewPage getTabletConversationViewPage() {
        return context.getPagesCollection().getPage(TabletConversationViewPage.class);
    }

    /**
     * Presses the conversation detail button on iPad to open a
     * ConversationDetailPopoverPage
     */
    @When("^I open (group )?conversation details on iPad$")
    public void IOpenConversationDetailsOniPad(String isGroup) {
        getTabletConversationViewPage().tapConversationDetailsIPadButton();
    }
}
