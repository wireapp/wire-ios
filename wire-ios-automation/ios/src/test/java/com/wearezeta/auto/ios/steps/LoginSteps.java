package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.email.messages.VerificationMessage;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.*;
import com.wearezeta.auto.ios.pages.team_creation.TCVerificationCodePage;
import com.wearezeta.auto.ios.pages.webview.WebViewPage;
import io.cucumber.java.en.When;

public class LoginSteps {
  IOSTestContext context;

  public LoginSteps(IOSTestContext context) {
    this.context = context;
  }

  private WelcomePage getWelcomePage() {
    return context.getPagesCollection().getPage(WelcomePage.class);
  }

  private IOSPage getCommonPage() {
    return context.getPagesCollection().getPage(IOSPage.class);
  }

  private CustomBackendRedirectionPage getCustomBackendRedirectionPage() {
    return context.getPagesCollection().getPage(CustomBackendRedirectionPage.class);
  }

  private IOSPage getIOSPage() {
    return context.getPagesCollection().getPage(IOSPage.class);
  }

  private LoginPage getLoginPage() {
    return context.getPagesCollection().getPage(LoginPage.class);
  }

  private WebViewPage getWebViewPage() {
    return context.getPagesCollection().getPage(WebViewPage.class);
  }

  private TCVerificationCodePage getVerificationCodePage() {
    return context.getPagesCollection().getPage(TCVerificationCodePage.class);
  }

  private FirstTimeOverlay getFirstTimeOverlay() {
    return context.getPagesCollection().getPage(FirstTimeOverlay.class);
  }

  @When("I login to Wire as (.*)")
  public void iLogin(String name) {
    ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(name);
    getCommonPage().openDeepLinkForDefault();
    context.startPinging();
    Timedelta.ofSeconds(3).sleep();
    context.stopPinging();
    getWebViewPage().tapOpenButton();
    context.startPinging();
    Timedelta.ofSeconds(3).sleep();
    context.stopPinging();
    getCustomBackendRedirectionPage().tapProceedButton();
    getWelcomePage().tapLoginButton();
    getLoginPage().loginAs(user.getEmail(), user.getPassword());
    if (getCommonPage().isNotNowOnPasswordPromptVisible()) {
      getCommonPage().tapNotNowOnPasswordPrompt();
    }
    // Accept first time overlay
    getFirstTimeOverlay().accept();
  }


  @When("I login to the default email verified backend as (.*)")
  public void iLoginToTheDefaultBackendAsName(String name) throws Exception {
    ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(name);

    // Open default backend
    getCommonPage().openDeepLinkForDefault();
    getCustomBackendRedirectionPage().tapProceedButton();

    // Enroll simulator in touch ID
    context.enrollSimulatorTouchID();

    // Start email inbox monitoring
    getIOSPage().startVerificationEmailMonitoring(user, context);

    // Login as user
    getWelcomePage().tapLoginButton();
    getIOSPage().startVerificationEmailMonitoring(user, context);
    getLoginPage().loginAs(user.getEmail(), user.getPassword());

    // Enter email verification code
    VerificationMessage verificationInfo = new VerificationMessage(context.getVerificationMessage().get());
    getVerificationCodePage().enterVerificationCode(verificationInfo.getXZetaCode());

    // Dismiss password prompt
    if (getCommonPage().isNotNowOnPasswordPromptVisible()) {
      getCommonPage().tapNotNowOnPasswordPrompt();
    }

    // Verify biometric
    context.getPagesCollection().getPage(IOSPage.class)
        .performTouchID(true);

    // Accept first time overlay
    getFirstTimeOverlay().accept();

    // Verify biometric
    context.startPinging();
    Timedelta.ofSeconds(2).sleep();
    context.stopPinging();
    context.getPagesCollection().getPage(IOSPage.class)
        .performTouchID(true);
  }
}
