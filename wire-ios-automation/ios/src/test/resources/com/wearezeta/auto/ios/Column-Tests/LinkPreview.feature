Feature: Link Preview

  @TC-4995 @col1
  Scenario Outline: I should not see link preview on receiving/sharing a link
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName1>", "label": "<DeviceName1>"}], "<Member2>": [{"name": "<DeviceName2>"}]}
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<GroupConversationName>" in conversation list
    And I type the "<Link>" message and send it
    And I wait for 3 seconds
    Then I do not see link preview container in the conversation view
    And I do not see link preview image in the conversation view
    When I navigate back to conversations list
    And I open conversation "<GroupConversationName>" in conversation list
    Then I do not see link preview container in the conversation view
    When User <Member2> sends 1 "<Link1>" message to conversation <GroupConversationName>
    And I wait for 3 seconds
    Then I do not see link preview container in the conversation view
    And I do not see link preview image in the conversation view

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName     | GroupConversationName | DeviceName1 | Link                 | Link1                                                        | DeviceName2 |
      | user1Name | user2Name | user3Name | File sharing | FileSharing           | devcie1     | https://github.com/  | https://www.youtube.com/watch?v=xd955wt1Bs0&feature=youtu.be | device2     |
