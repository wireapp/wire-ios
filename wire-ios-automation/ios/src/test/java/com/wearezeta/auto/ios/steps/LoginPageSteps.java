package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.usrmgmt.NoSuchUserException;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.*;
import static org.hamcrest.MatcherAssert.assertThat;

import java.util.logging.Logger;

import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;

import io.cucumber.java.en.*;

public class LoginPageSteps {

    private static final Logger log = ZetaLogger.getLog(LoginPageSteps.class.getSimpleName());
    private IOSTestContext context;

    public LoginPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private LoginPage getLoginPage() {
        return context.getPagesCollection().getPage(LoginPage.class);
    }

    /**
     * Verifies whether sign in screen is the current screen
     */
    @Given("^I see sign in screen$")
    public void ISeeSignInScreen() {
        assertThat("Login page is not visible", getLoginPage().isVisible());
    }

    @When("^I accept Connect to server alert$")
    public void iAcceptConnectToServerAlert() {
        getLoginPage().acceptConnectToServerAlert();
    }

    @When("^I accept Open in Wire alert$")
    public void iAcceptOpenInWireAlert() {
        getLoginPage().acceptOpenInWireAlert();
    }

    /**
     * Tap EMAIL tab caption on log in screen
     */
    @When("^I switch to Email Log In tab$")
    public void ITapEmailButton() {
        getLoginPage().switchToEmailLogin();
    }

    @Given("^I sign in user (.*) with email$")
    public void iSignInUsingEmail(String nameAlias) {
        ClientUser user = null;
        try {
            user = context.getUsersManager().findUserByNameOrNameAlias(nameAlias);
        } catch (NoSuchUserException e) {
            try {
                // search for user by email aliases in case name is specified
                user = context.getUsersManager().findUserByEmailOrEmailAlias(nameAlias);
            } catch (NoSuchUserException ex) {
                log.severe("Could not find user by name alias or email alias in users manager");
            }
        }
        log.info("Login with email " + user.getEmail() + " and password " + user.getPassword());
        LoginPage page = getLoginPage();
        log.info("Enter credentials");
        page.setLogin(user.getEmail());
        page.setPassword(user.getPassword());
        log.info("Tap login button");
        page.tapLoginButton();
    }

    @Given("^I sign in user (.*) with fast login$")
    public void iSignInUsingFastLogin(String nameAlias) {
        ClientUser user = null;
        try {
            user = context.getUsersManager().findUserByNameOrNameAlias(nameAlias);
        } catch (NoSuchUserException e) {
            try {
                // search for user by email aliases in case name is specified
                user = context.getUsersManager().findUserByEmailOrEmailAlias(nameAlias);
            } catch (NoSuchUserException ex) {
                log.severe("Could not find user by name alias or email alias in users manager");
            }
        }
        log.info("Fast login with email " + user.getEmail() + " and password " + user.getPassword());
        if (context.isDriverCreated()) {
            throw new RuntimeException("The fast login step can only be used before the driver is created! "
                    + "Make sure you do not use the 'I tap Login button on Welcome page' step before.");
        }
        if (context.getScenario().hasTag("fastlogin")) {
            throw new RuntimeException("Please remove @fastlogin for tests using this step!");
        }
        context.setFastLoginUser(user);
        context.getPagesCollection().getPage(WelcomePage.class).tapLoginButton();
    }

    /**
     * Taps Login button on the corresponding screen
     */
    @When("^I tap Login button on Login page$")
    public void ITapSignInButtonBund() {
        getLoginPage().tapLoginButton();
    }

    /**
     * Taps Login button on the corresponding screen
     */
    @When("^I attempt to tap Login button$")
    public void IAttemptToTapLoginButton() {
        getLoginPage().tapLoginButton();
    }

    /**
     * Assert that the login button is disabled.
     */

    @Then("^I don't see the Login button$")
    public void IDontSeeTheLoginButton() {
        assertThat("I see the the login button.", !getLoginPage().isLoginButtonInvisible());
    }

    /**
     * Types login string into the corresponding input field on sign in page
     *
     * @param login login string (usually it is user email)
     */
    @When("^I enter login (.*) on Login page$")
    public void IEnteredLogin(String login) {
        login = context.getUsersManager()
                .replaceAliasesOccurrences(login, ClientUsersManager.FindBy.EMAIL_ALIAS);
        getLoginPage().setLogin(login);
    }

    @When("^I login as (.*)$")
    public void ILogin(String email) {
        ClientUser user = context.getUsersManager().findUserByEmailOrEmailAlias(email);
        getLoginPage().setLogin(user.getEmail());
        getLoginPage().setPassword(user.getPassword());
        getLoginPage().tapLoginButton();
    }

    @When("I login")
    public void iLogin() {
        ClientUser me = context.getUsersManager().getSelfUser().get();
        getLoginPage().setLogin(me.getEmail());
        getLoginPage().setPassword(me.getPassword());
        getLoginPage().tapLoginButton();
    }

    /**
     * Types password string into the corresponding input field on sign in page
     *
     * @param password password string
     */
    @When("^I enter password (.*) on Login page$")
    public void IEnterLoginPassword(String password) {
        password = context.getUsersManager()
                .replaceAliasesOccurrences(password, ClientUsersManager.FindBy.PASSWORD_ALIAS);
        getLoginPage().setPassword(password);
    }

    @Then("^I (do not )?see Phone login tab on Login page$")
    public void iSeePhoneLogin(String shouldNotSee) {
        if (shouldNotSee == null) {
            assertThat("Phone Login is not visible", getLoginPage().isPhoneLoginVisible());
        } else {
            assertThat("Phone Login is visible", getLoginPage().isPhoneLoginInvisible());
        }
    }

    @Then("^I should not see Company Login button on Login page$")
    public void iShouldNotSeeCompanyLoginButton() {
        assertThat("Company Login button is visible.", getLoginPage().isCompanyLoginButtonInvisible());
    }

    @Then("^I am signed in properly$")
    public void iAmSignedInProperly() {
        assertThat("Can't find profile button. Are we logged in?", getLoginPage().waitForLoginProperly());
    }

    @Then("I see Login page")
    public void iDoNotSeeLoginPage() {
        getLoginPage().isVisible();
    }
}
