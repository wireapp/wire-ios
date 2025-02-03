package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.MapViewPage;
import io.cucumber.java.en.When;

public class MapViewPageSteps {
    IOSTestContext context;

    public MapViewPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private MapViewPage getMapViewPage()  {
        return context.getPagesCollection().getPage(MapViewPage.class);
    }

    @When("^I tap Send location button from map view$")
    public void ITapSendLocationButtonFromMapView()  {
        getMapViewPage().clickSendLocationButton();
    }
}
