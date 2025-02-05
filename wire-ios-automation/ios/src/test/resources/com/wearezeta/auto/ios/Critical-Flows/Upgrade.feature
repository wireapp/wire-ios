Feature: Upgrade

  @flows @TC-8585
  Scenario Outline: I want to update from previous version to the current one (team acc)
    Given The device is reset before and after the test
    And All other versions of Wire are uninstalled
    And I install the old version of Wire
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And Users adds the following devices: {"<TeamOwner>": [{"name": "<DeviceName>"}]}
    And User <Member1> is me
    When I login to Wire as <Member1>
    And I accept notification permission alert if visible
    And I am signed in properly
    And User <TeamOwner> sends 1 default message to conversation <ConversationName>
    And User <TeamOwner> sends 1 image file <Picture> to conversation <ConversationName>
    And I accept alert if visible
    And I see conversations list
    # To let the content to be synchronized
    And I wait for 5 seconds
    And I upgrade Wire to the recent version
    And I restore Wire
    And I accept alert if visible
    And I perform successful Touch ID
    And I accept alert if visible
    And I am signed in properly
    And I see conversations list
    When I open conversation "<ConversationName>" in conversation list
    Then I see 1 photo in the conversation view
    And I see 1 default message in the conversation view
    When I type the default message and send it
    # This is to make the keyboard invisible
    And I navigate back to conversations list
    When I open conversation "<ConversationName>" in conversation list
    And I scroll to the bottom of the conversation
    Then I see 2 default messages in the conversation view

    Examples:
      | TeamOwner | TeamName   | Member1   |  Member2   | ConversationName | Picture     | DeviceName | Member1Email | Password        |
      | user1Name | TeamSmart  | user2Name |  user3Name | Upgrade Test     | testing.jpg | device     | user2Email   | user1Password   |