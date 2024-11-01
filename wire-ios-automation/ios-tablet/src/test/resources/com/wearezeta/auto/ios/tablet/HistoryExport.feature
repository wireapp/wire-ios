Feature: History Export

  @C669488 @unstable @landscape
  Scenario Outline: Teams: I want to export a backup [LANDSCAPE]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> is me
    And I sign in user <TeamOwner> with fast login
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Back Up Conversations
    When I initiate history backup from Settings
    And I type password "<Password>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I see correct name of backup file for user <TeamOwner> on File Saving Popup
    And I tap Save to Files button on File Saving Popup
    And I tap On My iPad on File Saving Popup
    And I tap Save button on File Saving Popup
    Then I verify history backup for user <TeamOwner> from Settings is successfully completed

    Examples:
      | TeamOwner | TeamName   | Password     |
      | user1Name | Duck Tales | Gut3nM0rg3n! |
