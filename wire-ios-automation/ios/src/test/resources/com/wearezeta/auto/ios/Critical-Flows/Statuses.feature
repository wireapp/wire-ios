Feature: Statuses

  @flows @03
  Scenario Outline: Enterprise user goes for lunch break followed by focus time
  #Enterprise Users A, B exist
    Given I allow camera access
    And I allow microphone access
    And There is a team owner "<UserA>" with team "<TeamName>"
    And TeamOwner "<UserA>" enables conference calling feature for team <TeamName> via backdoor
    And User <UserA> adds users <UserB> to team <TeamName> with role Member
  #There is a group conversation between A & B
    And User <UserA> has conversation <GroupName> with <UserB> in team <TeamName>
    And User <UserA> is me
    And <UserB> starts instance using chrome
  #1. User A logs in and doesn't set a status
    When I tap Login button on Welcome page
    And I login
    And I accept First Time overlay
    And I accept alert if visible
  #2. User B sends a message in the group conversation and User A can follow the notification to the conversation and reply
    Given User <UserB> sends 1 "<Message>" messages to conversation <GroupName>
    When I open group conversation "<GroupName>" in conversation list
    And I see last message in the conversation view contains expected message <Message>
    When I long tap "<Message>" message in conversation view
    And I tap on Reply on edit menu
    And I type the "Replying!" message and send it
    Then I see 1 reply in the conversation view
    When I navigate back to conversations list
   # When I tap my profile name in conversation list
    When I tap on my profile photo in conversation list
    And I tap on set a status button on self profile page
    And I tap status Away
    And I tap Ok Button on Enterprise alert
    And I tap on profile close button
  #4. User B calls and User A does not get notification * if possible to test in automation, but also this would preferably be a lower level test anyways
    When <UserB> calls me
    # We don't have a step for no notification and this might not be possible
    # Also considered bad practice to check for the absence of something, should be tested at a lower level
    #Then I do not see alert
  #5. User A sets status to Busy and backgrounds app
    When I restore Wire
    When I tap on my profile photo in conversation list
    And I tap on set a status button on self profile page
    And I tap status Busy
    And I tap Ok Button on Enterprise alert
    And I tap on profile close button
    And <UserB> stops outgoing call to me
    And I minimize Wire
    And I restore Wire
  #6. User B messages the group
    Given User <UserB> sends 1 "<Message>" messages to conversation <GroupName>
  #7. User A does not get a notification * if possible to test in automation, but also this would preferably be a lower level test anyways
    #TODO: We don't have a step for no notification and this might not be possible
    And I open group conversation "<GroupName>" in conversation list
    And I type the "I'll reply later" message and send it
  #10. User A sets status to available
  #11. User B sends a message to group
  #12. User A sees message notification and clicks it to go to group
    Examples:
      | UserA     | UserB     | GroupName | TeamName | Message    |
      | user1Name | user2Name | GroupName | TeamName | you there? |