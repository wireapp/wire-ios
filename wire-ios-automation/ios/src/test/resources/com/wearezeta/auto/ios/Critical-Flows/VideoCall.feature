Feature: Video Calls

  @flows @TC-8586
  Scenario Outline: Team members attending stand up (Video call)
    Given I allow camera access
    And I allow microphone access
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And TeamOwner "<TeamOwner>" waits and enables conference calling feature for team <TeamName> via backdoor
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
    And I login to Wire as <TeamOwner>
    And  I open search screen
    And I open create group screen
    And I enter group name "<ConversationTitle>" on New Group page
    And I tap Next button on New Group page
    And I type first 3 letters of name "<Member1>" in search input field on Add People page
    And I select search result item <Member1> on Add People page
    And I type first 3 letters of name "<Member2>" in search input field on Add People page
    And I select search result item <Member2> on Add People page
    And I tap Create button on Add People page
    And User <TeamOwner> sends 1 default messages to conversation <ConversationTitle>
    And I navigate back to conversations list
    And I open conversation "<ConversationTitle>" in conversation list
    And I tap Video Call button
    When I tap Minimize button on Calling overlay
    And I type the default message and send it
    When I navigate back to conversations list
    And I open group conversation "<ConversationTitle>" in conversation list
    And I type the default message and send it
    And I tap ellipsis button from input tools
    And I tap Ping button from input tools
    When I restore Calling overlay
    And I see Video Calling overlay
    And I switch Off camera button
    And I Switch ON camera button
    When I tap Leave button on Calling overlay
    Then I do not see Calling overlay

    Examples:
      | Member1   | TeamOwner | TeamName  |  Member2   | ConversationTitle   |
      | user1Name | user3Name | SuperTeam |  user2Name | conversation        |
