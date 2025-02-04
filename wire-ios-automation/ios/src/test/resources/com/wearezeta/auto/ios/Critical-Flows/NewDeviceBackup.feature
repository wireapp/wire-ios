Feature: New Device with Backup

  @flows @TC-8582
  Scenario Outline: Employee setting up  a new device using backup
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And I tap Login button on Welcome page
    And I sign in user <Member1> with email
    And I accept First Time overlay
    And I accept alert if visible
    And I open conversation "<Member2>" in conversation list
    And I tap on text input
    When I type the <Text> message
    And I tap Send Message button in conversation view
    And I navigate back to conversations list
    And I open settings screen
    And I select settings item Account
    And I select settings item Back Up Conversations
    When I initiate history backup from Settings
    And I type password "<BackupPassword>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I tap Save to Files button on File Saving Popup
    When I tap Save button on File Saving Popup
    And I tap on the account back button
    And I select settings item Log Out
    And I type my password into the alert input field
    And I accept alert
    And I tap Login button on Welcome page
    And I sign in user <Member1> with email
    When I tap Restore from backup button on First Time overlay
    And I tap Choose Backup File button on the alert
    And I tap Browse button twice on bottom of File Choose Dialog
    And I tap On My iPhone on File Choose Dialog
    And I tap file containing user1UniqueUsername in File Choose Dialog
    And I type "<BackupPassword>" text into the alert input field
    And I accept alert
    And I wait for 5 seconds
    And I accept alert if visible
    And I open conversation "<Member2>" in conversation list
    And I see last message in the conversation view is expected message <Text>
    And I tap on text input
    When I type the <Text2> message
    And I tap Send Message button in conversation view
    Then I see last message in the conversation view is expected message <Text2>

    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | BackupPassword | Text | Text2 |
      | user1Name | user3Name | SuperTeam | user2Name | Aqa123456!     | Hi   | Text  |

