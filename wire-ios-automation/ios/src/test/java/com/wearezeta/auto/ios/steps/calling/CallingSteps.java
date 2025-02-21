package com.wearezeta.auto.ios.steps.calling;

import com.wearezeta.auto.common.CallingManager;
import com.wearezeta.auto.common.backend.Backend;
import com.wearezeta.auto.common.backend.BackendConnections;
import com.wearezeta.auto.common.backend.models.Conversation;
import com.wearezeta.auto.common.log.ZetaLogger;
import com.wearezeta.auto.common.usrmgmt.ClientUser;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.util.logging.Logger;

import javax.management.InstanceNotFoundException;
import java.util.*;

public class CallingSteps {
    IOSTestContext context;

    private static final Logger log = ZetaLogger.getLog(CallingSteps.class.getSimpleName());

    public CallingSteps(IOSTestContext context) {
        this.context = context;
    }

    /**
     * Make call to a specific user. You may instantiate more than one incoming
     * call from single caller by calling this step multiple times
     *
     * @param caller           caller name/alias
     * @param conversationName destination conversation name
     */
    @When("(\\w+) calls (\\w+)$")
    public void UserXCallsToUserYUsingCallBackend(String caller, String conversationName) throws Exception {
        context.getCallingManager().callToConversation(caller, conversationName);
    }

    /**
     * Stop outgoing or incoming call (audio and video) to the other side
     *
     * @param instanceUsers    comma separated list of usernames/aliases
     * @param conversationName destination conversation name
     */
    @When("^(.*) stops? (incoming call from|outgoing call to) (.*)")
    public void UserXStopsIncomingOutgoingCallsToUserY(String instanceUsers, String typeOfCall, String conversationName)
            throws Exception {
        if (typeOfCall.equals("incoming call from")) {
            context.getCallingManager()
                    .stopIncomingCall(context.getUsersManager()
                            .splitAliases(instanceUsers));
        } else {
            context.getCallingManager()
                    .stopOutgoingCall(context.getUsersManager()
                            .splitAliases(instanceUsers), conversationName);
        }
    }


    /**
     * Verify whether call status is changed to one of the expected values after
     * N seconds timeout
     *
     * @param caller           caller name/alias
     * @param conversationName destination conversation
     * @param expectedStatuses comma-separated list of expected call statuses. See
     *                         com.wearezeta.auto.common.calling2.v1.model.CallStatus for
     *                         more details
     * @param timeoutSeconds   number of seconds to wait until call status is changed
     */
    @Then("(.*) verif(?:ies|y) that call status to (.*) is changed to (.*) in (\\d+) seconds?$")
    public void UserXVerifiesCallStatusToUserY(String caller,
                                               String conversationName, String expectedStatuses, int timeoutSeconds)
            throws Exception {
        context.getCallingManager()
                .verifyCallingStatus(caller, conversationName, expectedStatuses, timeoutSeconds);
    }

    /**
     * Verify whether waiting instance status is changed to one of the expected
     * values after N seconds timeout
     *
     * @param callees          comma separated list of callee names/aliases
     * @param expectedStatuses comma-separated list of expected call statuses. See
     *                         com.wearezeta.auto.common.calling2.v1.model.CallStatus for
     *                         more details
     * @param timeoutSeconds   number of seconds to wait until call status is changed
     */
    @Then("(.*) verif(?:ies|y) that waiting instance status is changed to (.*) in (\\d+) seconds?$")
    public void UserXVerifiesCallStatusToUserY(String callees,
                                               String expectedStatuses, int timeoutSeconds) throws Exception {
        context.getCallingManager().verifyAcceptingCallStatus(context.getUsersManager()
                .splitAliases(callees), expectedStatuses, timeoutSeconds);
    }

    /**
     * Verify that the instance has X active flows
     *
     * @param callees       comma separated list of callee names/aliases
     * @param numberOfFlows expected number of flows
     */
    @Then("^Users? (.*) verif(?:ies|y) to have (\\d+) peer connections?$")
    public void UserXVerifesHavingXPeerConnections(String callees, int numberOfFlows) throws Exception {
        context.getCallingManager().verifyPeerConnections(callees, numberOfFlows);
    }

    /**
     * Verify that the instance has an established CBR connection
     *
     * @param callees       comma separated list of callee names/aliases
     */
    @Then("^Users? (.*) verif(?:ies|y) to have CBR connection$")
    public void UserXVerifesHavingCbrConnections(String callees) throws Exception {
        context.getCallingManager().verifyCbrConnections(callees);
    }

    /**
     * Verify that each flow of the instance had incoming and outgoing packets for audio
     * running over the line
     *
     * @param callees comma separated list of callee names/aliases
     */
    @Then("^Users? (.*) verif(?:ies|y) to send and receive audio$")
    public void UserXVerifesAudio(final String callees) throws Exception {
        context.getCallingManager().verifySendAndReceiveAudio(callees);
    }

    @When("(.*) starts? instances? using (.*)$")
    public void UserXStartsInstance(String callees, String callingServiceBackend) {
        context.getCallingManager()
                .startInstances(context.getUsersManager().splitAliases(callees),
                        callingServiceBackend, "iOS", context.getScenario().getName());
    }

    @When("(.*) starts? 2FA instances? using (.*)$")
    public void UserXStarts2FAInstance(String callees, String callingServiceBackend) {
        context.startPinging();
        List<String> calleeNames = context.getUsersManager().splitAliases(callees);
        for (String calleeName : calleeNames) {
            ClientUser user = context.getUsersManager().findUserByNameOrNameAlias(calleeName);
            Backend backend = BackendConnections.get(user);

            if (callingServiceBackend.contains("zcall")) {
                String teamID = backend.getAllTeams(user).get(0).getId();
                backend.unlock2FAuthenticationFeature(teamID);
                backend.disable2FAuthenticationFeature(teamID);
                context.getCallingManager().startInstances(Collections.singletonList(calleeName), callingServiceBackend,
                        "iOS", context.getScenario().getName());
                backend.enable2FAuthenticationFeature(teamID);
                backend.lock2FAuthenticationFeature(teamID);
            } else {
                String verificationCode = backend.getVerificationCode(user);
                log.info("verificationCode: " + verificationCode);
                context.getCallingManager().startInstance(calleeName, verificationCode,
                        callingServiceBackend, "iOS", context.getScenario().getName());
            }
        }
        context.stopPinging();
    }

    /**
     * Automatically accept the next incoming call for the particular user as
     * soon as it appears in UI. Waiting instance should be already created for
     * this particular user
     *
     * @param callees comma separated list of callee names/aliases
     */
    @When("(.*) accepts? next incoming call automatically$")
    public void UserXAcceptsNextIncomingCallAutomatically(String callees) throws Exception {
        userXVerifesInstanceStatusToUserY(callees, "started", 20);
        context.getCallingManager()
                .acceptNextCall(context.getUsersManager()
                        .splitAliases(callees));
    }

    @Then("Users? (.*) verif(?:y|ies) that instance status is changed to (.*) in (\\d+) seconds?$")
    public void userXVerifesInstanceStatusToUserY(String callees,
                                                  String expectedStatuses, int timeoutSeconds) throws Exception {
        context.startPinging();
        try {
            context.getCallingManager().verifyInstanceStatus(context.getUsersManager().splitAliases(callees),
                    expectedStatuses, timeoutSeconds);
        } finally {
            context.stopPinging();
        }
    }

    /**
     * Make a video call to a specific user.
     *
     * @param callerName       name of caller
     * @param conversationName destination conversation name
     */
    @When("(.*) starts? a video call to (.*)$")
    public void UserXStartVideoCallsToUserYUsingCallBackend(String callerName, String conversationName) throws
            Exception {
        final ClientUser caller = context.getUsersManager().findUserByNameOrNameAlias(callerName);
        Conversation conversation = context.getCommonSteps().getConversation(callerName, conversationName);
        context.getCallingManager().startVideoCallToConversation(caller, conversation);
    }

    private CallingManager getCallingManager() {
        return context.getCallingManager();
    }

    /**
     * Switch on/off video
     *
     * @param callees username/alias of the screensharing initiator
     * @param state either 'on' or 'off'
     */
    @When("User (.*) switches video (on|off)$")
    public void userXSwitchesVideoOn(String callees, String state) throws InstanceNotFoundException {
        final List<String> users = context.getUsersManager().splitAliases(callees);
        if (state.equalsIgnoreCase("on")) {
            getCallingManager().switchVideoOn(users);
        } else {
            getCallingManager().switchVideoOff(users);
        }
    }
}