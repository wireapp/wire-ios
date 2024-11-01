package com.wearezeta.auto.ios.tablet.steps;

import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.FirstTimeOverlay;
import com.wearezeta.auto.ios.tablet.pages.TabletLoginPage;

import io.cucumber.java.en.Given;

import java.util.logging.Logger;

public class TabletLoginPageSteps {

    private static final Logger log = ZetaLogger.getLog(TabletLoginPageSteps.class.getSimpleName());

    private IOSTestContext context;

    public TabletLoginPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private TabletLoginPage getTabletLoginPage() {
        return context.getPagesCollection().getPage(TabletLoginPage.class);
    }

    private FirstTimeOverlay getFirstTimeOverlayPage() {
        return context.getPagesCollection().getPage(FirstTimeOverlay.class);
    }

    /**
     * Signing in on tablet with login and password
     */
    @Given("^I Sign in on tablet using my email$")
    public void GivenISignInUsingEmail() {
        final ClientUser self = context.getUsersManager().getSelfUserOrThrowError();
        getTabletLoginPage().setLogin(self.getEmail());
        getTabletLoginPage().setPassword(self.getPassword());
        getTabletLoginPage().tapLoginButton();
    }
}
