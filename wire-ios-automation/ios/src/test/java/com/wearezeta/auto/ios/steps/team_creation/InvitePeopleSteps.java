package com.wearezeta.auto.ios.steps.team_creation;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.team_creation.InvitePeoplePage;
import io.cucumber.java.en.When;

public class InvitePeopleSteps {
    IOSTestContext context;

    public InvitePeopleSteps(IOSTestContext context) {
        this.context = context;
    }

    private InvitePeoplePage getInvitePeoplePage()  {
        return context.getPagesCollection()
                .getPage(InvitePeoplePage.class);
    }

    @When("^I tap Done button on Invite People page$")
    public void ITapDoneButtonOptionsOnInvitePeoplePage()  {
        getInvitePeoplePage().tapDoneButton();
    }
}
