Feature: On-Premises

  @TC-4996 @onpremise @col1 @col3 @shouldbeui
  Scenario: I should see the domain name of custom backend
    When I open default backend via deep link in safari
    Then I see redirection title on backend redirection page
    And I see backend information of backend default
    When I tap Proceed button on backend redirection page
    Then I see sign in screen

  @TC-4997 @onpremise @col1 @col3 @SF.Channel @TSFI.UserInterface @S0.1 @BundSecurity @shouldbeui
  Scenario: I should not see phone login on build with disabled phone login
    When I see sign in screen
    Then I do not see Phone login tab on Login page

  @TC-4998 @onpremise @col1 @col3 @SF.Locking @TSFI.UserInterface @S0.1 @BundSecurity
  Scenario Outline: I should see passcode overlay after login on custom backend with enabled encryption on rest
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    Given User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly

    Examples:
      | TeamOwner | TeamName |
      | user1Name |  hoffman |

  @TC-4999 @SF.IOS-VSNFDAREA @TSFI.UserInterface @S0.1 @col1 @BundSecurity
  Scenario Outline: I should not be able to copy/paste messages when clipboard is disabled on build time with CLIPBOARD_ENABLED=0
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceMember1>"}], "<TeamOwner>": [{"name": "<DeviceTeamOwner>"}]}
    And User <TeamOwner> has conversation <GroupChatName> with <Member1> in team <TeamName>
    And User <Member1> is me
    When I login to the default email verified backend as <Member1>
    Then I am signed in properly
    When User <TeamOwner> sends 1 default message to conversation <GroupChatName>
    When I open conversation "<GroupChatName>" in conversation list
    Then I see at least one message in the conversation view
    When I long tap default message in conversation view
    Then I do not see Copy on edit menu
    When I tap on Cancel on edit menu
    When I long tap on text input
    Then I do not see Paste on edit menu
    When I load clipboard content from string "<DeviceMember1>"
    And I long tap on text input
    Then I do not see Paste on edit menu
    And I do not see Share on edit menu
    When I type the default message and send it
    And I long tap default message in conversation view
    Then I do not see Copy on edit menu
    When I tap on Edit on edit menu
    And I tap on text input
    And I tap on Select All on edit menu
    Then I do not see Copy on edit menu
    And I do not see Share on edit menu
    But I tap Cancel button on Edit control

    Examples:
      | Member1   | TeamOwner | TeamName | DeviceMember1 | GroupChatName | DeviceTeamOwner |
      | user1Name | user2Name | BestTeam | device1       | Group         | device2         |
