package com.wearezeta.auto.ios.steps.team_creation;

import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.team_creation.TCVerificationCodePage;
import io.cucumber.java.en.When;

public class TCVerificationCodePageSteps {
    IOSTestContext context;

    public TCVerificationCodePageSteps(IOSTestContext context) {
        this.context = context;
    }

    private TCVerificationCodePage getVerificationCodePage()  {
        return context.getPagesCollection().getPage(TCVerificationCodePage.class);
    }

    @When("^I enter \"(.*)\" as Verification Code on Verification Code page$")
    public void IEnterWrongVerificationCode(String code) {
        getVerificationCodePage().enterVerificationCode(code);
    }

    @When("^I type 2FA verification code (.*) into fields$")
    public void IEnter2FAVerificationCodeOnVerificationCodePage(String code) {
        getVerificationCodePage().enterVerificationCode(code);
    }

    @When("^I tap Resend Code button on Verification Code page$")
    public void ITapResendCodeOptionsButtonOnVerificationCodePage()  {
        getVerificationCodePage().tapResendCode();
    }

    @When("^I tap Back button on Verification Code page$")
    public void ITapBackButtonOnVerificationCodePage()  {
        getVerificationCodePage().tapBack();
    }

    @When("^I accept Please enter a valid code alert on Verification Code page$")
    public void iAcceptAlert()  {
        getVerificationCodePage().acceptAlert();
    }
}
