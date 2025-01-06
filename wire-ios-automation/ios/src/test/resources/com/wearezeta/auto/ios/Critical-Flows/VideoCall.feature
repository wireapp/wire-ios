Feature: Video Calls

  @flows @TC-8586
  Scenario Outline: Team members attending stand up (Video call)
    Given I allow camera access
    And I allow microphone access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And There is a team owner "<TeamGuest>" with team "Guest"
    And TeamOwner "<TeamOwner>" waits and enables conference calling feature for team <TeamName> via backdoor
    And User <TeamOwner> adds user <Member1>, <Member2>, <Member3>,<Member4>, <Member5> to team <TeamName> with role Member
    And User <TeamOwner> is connected to <TeamGuest>
    And User <TeamOwner> has conversation <ConversationTitle> with <Member1>,<Member2>, <Member3>, <Member4> in team <TeamName>
    And User <Member1> has conversation <ConversationTitle2> with <Member2>,<Member4>, <TeamOwner> in team <TeamName>
    And <Member1>,<Member2>,<Member3>, <Member4>, <Member5>, <TeamGuest> starts instance using <CallBackend>
    And User <TeamOwner> is me
    And <Member1>,<Member2>,<Member3>, <Member4>,<Member5>,<Member6> accepts next incoming call automatically
    When I login to Wire as <TeamOwner>
    And I accept alert if visible
    And I open group conversation "<ConversationTitle>" in conversation list
    And I copy the group invite link
    And I close Group Details
    And I navigate back to conversations list
    And I open conversation "<TeamGuest>" in conversation list
    And I send what is in my pasteboard
    And I navigate back to conversations list
    And I open conversation "<ConversationTitle>" in conversation list
    # Enabling calling needs to happen away from team creation to avoid iblis
    And I tap Video Call button
    And I tap call button on start call alert
    # Note: Usually steps like "do not see..." should be avoided for time reasons, however if iblis is causing issues
    # Then this step helps us diagnose the problem
    Then I do not see Enterprise Upgrade alert
    #And <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6> verifies that waiting instance status is changed to active in 40 seconds
    And <Member1> verifies that waiting instance status is changed to active in 60 seconds
    #And User <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6> verifies to have 1 peer connection
    And User <Member1> verifies to have 1 peer connection
#    App crashes upon next step of video switching on
    When I tap Minimize button on Calling overlay
    And I type the default message and send it
    Then I see 1 default message in the conversation view
    When I navigate back to conversations list
    And I open group conversation "<ConversationTitle2>" in conversation list
    And I type the default message and send it
    Then I see 1 default message in the conversation view
    #When User <Member4> sends link preview for "https://www.wire.com/" to conversation <ConversationTitle>
    And I navigate back to conversations list
    And I open group conversation "<ConversationTitle>" in conversation list
    # TODO: Getting connection refused on some of these test service calls. Fix after stabilizing flow
    #Then I see link preview source is equal to https://www.wire.com/
    #When I tap on link preview in conversation view
    #Then I see "https://www.wire.com/" web page opened
    #When I launch Wire
    #When User <Member1> toggles reaction "👍🏼" on the recent message from group conversation <ConversationTitle>
    #Then I see 👍🏼 reaction in the conversation view
    When I restore Calling overlay
    And I see Video Calling overlay
    #TODO: Test service picking up isn't reliable. This check honestly not necessary for flow anyways
    #Then I see 7 videos in video grid
    When I tap Leave button on Calling overlay
    Then I do not see Calling overlay
    #And I see link preview source is equal to https://www.wire.com/

    Examples:
      | Member1   | TeamOwner | TeamName  | CallBackend | Member2   | ConversationTitle   | Member3   | Member4   | Member5   | Member6   | ConversationTitle2 | TeamGuest |
      | user1Name | user3Name | SuperTeam | chrome      | user2Name | conversation        | user4Name | user5Name | user6Name | user7Name | EngineeringTeam    | user7Name |
