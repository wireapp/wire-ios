package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.UniqueUsernameTakeoverPage;
import io.cucumber.java.en.When;

import java.util.logging.Logger;

public class UniqueUsernameTakeoverPageSteps {

    private static final Logger log = ZetaLogger.getLog(UniqueUsernameTakeoverPageSteps.class.getSimpleName());
    IOSTestContext context;

    public UniqueUsernameTakeoverPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private UniqueUsernameTakeoverPage getPage()  {
        return context.getPagesCollection()
                .getPage(UniqueUsernameTakeoverPage.class);
    }

    @When("^I tap Keep This One button on Unique Username Takeover page$")
    public void iTapKeepThis()  {
        getPage().tapKeepThisOneButton();
    }
}
