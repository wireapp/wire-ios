package com.wearezeta.auto.ios.steps.services;

import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.ServiceCreationPage;
import com.wearezeta.auto.ios.pages.ServiceDetailPage;
import com.wearezeta.auto.ios.pages.TeamSearchUIPage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupDetailsPage;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

public class ServiceSteps {
    IOSTestContext context;

    public ServiceSteps(IOSTestContext context) {
        this.context = context;
    }

    private TeamSearchUIPage getTeamSearchUIPage() {
        return context.getPagesCollection().getPage(TeamSearchUIPage.class);
    }

    private ServiceDetailPage getServiceDetailPage() {
        return context.getPagesCollection().getPage(ServiceDetailPage.class);
    }

    @When("^I tap Services tab on Team Search UI page$")
    public void ITapServiceTab() {
        getTeamSearchUIPage().tapTeamSearchUITab();
    }

    @Then("^I tap Add Service button on service detail page$")
    public void ITapOnAddServiceOnServiceDetailPage(){
        getServiceDetailPage().addService();
    }
}
