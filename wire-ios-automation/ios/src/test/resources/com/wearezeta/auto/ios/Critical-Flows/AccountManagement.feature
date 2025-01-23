Feature: Account Management

  @flows @012
  Scenario Outline: Account Management
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> adds user <Member2> to team <TeamName> with role Member and without unique username
    And User adds the following device: {"<TeamOwner>": [{"name": "<Device>"}]}
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationTitle> with <Member1> in team <TeamName>
    And I see Welcome page
    And I tap Login button on Welcome page
    And I enter login <Member2Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I set the username to <Member2UniqueUsername>
    And I accept alert if visible
    And I open settings screen
    And I select settings item Options
    And I scroll to the bottom of the conversation
    And I toggle on lock with passcode option
    And I enter passcode <LockPasscode> to lock the app
    And I tap on lock passcode button
    And I tap on the settings back button
    And I select settings item Account
    And I select settings item Username
    When I clear Username input field on Settings page
    Then I see Save button state is Disabled on Unique Username page
    When I enter "<NewUsername>" name on Unique Username page
    When I tap Save button on Unique Username page
    And I select settings item Reset Password





    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | ConversationTitle | Member2Email  | Password      | Member2UniqueUsername | Device  | LockPasscode | NewUsername |
      | user1Name | user3Name | SuperTeam | user2Name | The Official Chat | user2Email    | user2Password | user2UniqueUsername   | device1 | Aqa123456!   |   NewName   |
