package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.email.messages.ActivationMessage;
import com.wearezeta.auto.common.email.messages.VerificationMessage;
import com.wearezeta.auto.common.email.messages.WireMessage;
import com.wearezeta.auto.common.email.handlers.ISupportsMessagesPolling;
import com.wearezeta.auto.common.email.MailboxProvider;
import com.wearezeta.auto.common.misc.Timedelta;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.common.usrmgmt.NoSuchUserException;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.IOSPage;
import com.wearezeta.auto.ios.pages.RegistrationPage;
import com.wearezeta.auto.ios.pages.team_creation.TCVerificationCodePage;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.hamcrest.MatcherAssert.assertThat;

import java.util.HashMap;
import java.util.Map;

public class RegistrationPageSteps {
    IOSTestContext context;

    public RegistrationPageSteps(IOSTestContext context) {
        this.context = context;
    }

    private RegistrationPage getRegistrationPage() {
        return context.getPagesCollection().getPage(RegistrationPage.class);
    }

    private TCVerificationCodePage getVerificationCodePage() {
        return context.getPagesCollection().getPage(TCVerificationCodePage.class);
    }

    private IOSPage getIOSPage() {
        return context.getPagesCollection().getPage(IOSPage.class);
    }

    /**
     * Verifies whether registration screen is the current screen
     */
    @Given("I see registration screen")
    public void ISeeRegistrationScreen() {
        assertThat("Registration screen is not visible", getRegistrationPage().isVisible());
    }

    @Then("I see password failure message")
    public void ISeePasswordFailureMessage() {
        assertThat("password failure message is not visible", getRegistrationPage().isPasswordFailureVisible());
    }

    @Given("I see password rules")
    public void ISeePasswordRules() {
        assertThat("password rules is not visible", getRegistrationPage().isPasswordRulesVisible());
    }

    /**
     * Click on I AGREE button to accept terms of service
     */
    @When("^I accept terms of service$")
    public void IAcceptTermsOfService() {
        getRegistrationPage().clickAcceptTOCButton();
    }

    @When("^I enter activation code for the email address of (.*)")
    public void iEnterActivationCodeForEmailString(String user) {
        final ClientUser clientUser = context.getUsersManager().findUserByNameOrNameAlias(user);
        getRegistrationPage().inputActivationCode(clientUser);
    }

    @When("^I enter registration name \"(.*)\"$")
    public void IEnterName(String name) {
        try {
            context.setUserToRegister(context.getUsersManager().findUserByNameOrNameAlias(name));
            getRegistrationPage().typeName(context.getUserToRegister().getName());
        } catch (NoSuchUserException e) {
            getRegistrationPage().typeName(name);
        }
    }

    @When("^I input (custom )?name (.*) and commit it$")
    public void IInputNameAndCommit(String isCustom, String name) {
        if (isCustom == null) {
            IEnterName(name);
        } else {
            getRegistrationPage().typeName(name);
        }
        getRegistrationPage().tapNameConfirmButton();
    }

    @When("^I set the username to (.*)$")
    public void IEnterUsername(String name) {
        context.setUserToRegister(context.getUsersManager().findUserByUniqueUsernameAlias(name));
        getRegistrationPage().typeUsername(context.getUserToRegister().getUniqueUsername());
        getRegistrationPage().tapUsernameConfirmButton();
    }

    @When("^I enter registration email \"(.*)\"$")
    public void IEnterEmail(String email) {
        try {
            context.setUserToRegister(context.getUsersManager().findUserByEmailOrEmailAlias(email));
            getRegistrationPage().typeEmail(context.getUserToRegister().getEmail());
        } catch (NoSuchUserException e) {
            getRegistrationPage().typeEmail(email);
        }
        getRegistrationPage().tapNameConfirmButton();
    }

    @When("^I set the password to \"(.*)\"$")
    public void IEnterPassword(String password) {
        try {
            context.setUserToRegister(context.getUsersManager().findUserByPasswordAlias(password));
            getRegistrationPage().typePassword(context.getUserToRegister().getPassword());
        } catch (NoSuchUserException e) {
            getRegistrationPage().typePassword(password);
        }
        getRegistrationPage().tapPasswordConfirmButton();
    }

    @When("^I clear password input$")
    public void IClearPasswordInput() {
        getRegistrationPage().clearPasswordInput();
    }

    /**
     * Start monitoring thread for activation email for the particular mailbox
     *
     * @param mbox   mailbox email address/an alias
     */
    @When("^I start activation email monitoring on mailbox (.*)")
    public void IStartActivationEmailMonitoringOnMbox(String mbox) throws Exception {
        ClientUser user = context.getUsersManager().findUserByEmailOrEmailAlias(mbox);

        final Map<String, String> expectedHeaders = new HashMap<>();
        expectedHeaders.put(WireMessage.ZETA_PURPOSE_HEADER_NAME, ActivationMessage.MESSAGE_PURPOSE);
        ISupportsMessagesPolling mailbox = MailboxProvider.getInstance(BackendConnections.get(user), user.getEmail());
        context.setActivationMessage(mailbox.getMessage(expectedHeaders, ActivationMessage.ACTIVATION_TIMEOUT));
    }

    @When("^I start verification email monitoring on mailbox (.*)")
    public void IStartVerificationEmailMonitoringOnMbox(String mbox) throws Exception {
        ClientUser user = context.getUsersManager().findUserByEmailOrName(mbox);
        getIOSPage().startVerificationEmailMonitoring(user, context);
    }

    @When("^I enter verification code from Email$")
    public void ICheckVerificationCodeInSubjectAndBody() throws Exception {
        VerificationMessage verificationInfo = new VerificationMessage(context.getVerificationMessage().get());
        getVerificationCodePage().enterVerificationCode(verificationInfo.getXZetaCode());

    }

    @When("^I wait until (\\d) mails arrived for (.*)$")
    public void IWaitUntilXMailsArrived(int count, String emailAlias) throws Exception {
        ClientUser user = context.getUsersManager().findUserByEmailOrEmailAlias(emailAlias);
        context.startPinging();
        try {
            ISupportsMessagesPolling mbox = MailboxProvider.getInstance(BackendConnections.get(user), user.getEmail());
            mbox.waitUntilMessagesCountReaches(user.getEmail(), count, Timedelta.ofMillis(0));
        } finally {
            context.stopPinging();
        }
    }

    /**
     * Activate email address using activation keys as soon as the corresponding message is received.
     * This steps expects mailbox monitoring to be already running
     *
     * @param address the expected email address for a user
     * @param user    user name/alias
     */
    @Then("^I verify email address (.*) for (.*)")
    public void IVerifyEmail(String address, String user) throws Exception {
        if (context.getActivationMessage() == null) {
            throw new IllegalStateException("Activation email monitoring is expected to be running");
        }
        context.getCommonSteps().activateRegisteredUserByEmail(context.getActivationMessage());
        address = context.getUsersManager()
                .replaceAliasesOccurrences(address, ClientUsersManager.FindBy.EMAIL_ALIAS);
        final ClientUser dstUser = context.getUsersManager()
                .findUserByNameOrNameAlias(user);
        dstUser.setEmail(address);
        context.setActivationMessage(null);
    }

    /**
     * Verifies that the email verification reminder on the login page is
     * displayed
     */
    @Then("^I see email verification reminder$")
    public void ISeeEmailVerificationReminder() {
        assertThat("Prompt not visible", getRegistrationPage().isEmailVerificationPromptVisible());
    }

    /**
     * Taps back button on registration screen
     */
    @When("^I tap Back button on Registration page$")
    public void ITapBackButtonOnRegistrationPage() {
        getRegistrationPage().tapBackButton();
    }
}
