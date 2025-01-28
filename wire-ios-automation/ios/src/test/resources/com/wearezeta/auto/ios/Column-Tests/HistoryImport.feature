Feature: History Import

  @TC-4981 @col1 @knownbug @WPB-11092
  Scenario Outline: I want to have the delivery statuses, likes, messages, system messages, assets, pings, failed-to-send messages, mute, archived statuses in my imported backup
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User Myself has 1:1 conversation with <Member1> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName1>"}], "<Member2>": [{"name": "<DeviceName2>"}], "Myself": [{"name": "M1", "label": "L1"}]}
    And I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I long tap alias conversation '<Member2>' in conversation list
    And I choose Archive from conversation list context menu
    And I swipe right on conversation <Member1> in Conversations view
    And I tap Notifications… conversation action button
    And I tap Nothing conversation action button
    And User <Member1> pings conversation Myself
    # Wait for sync
    And I wait for 2 seconds
    And User <Member1> sends 1 image file <Picture> to conversation Myself
    # Wait for sync
    And I wait for 3 seconds
    And User <Member1> sends 1 default message to conversation Myself
    # Wait for sync
    And I wait for 2 seconds
    And User Myself likes the recent message from user <Member1>
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Back Up Conversations
    And I initiate history backup from Settings
    And I type password "<BackupPassword>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I see correct name of backup file for user <TeamOwner> on File Saving Popup
    And I tap Save to Files button on File Saving Popup
    And I tap On My iPhone on File Saving Popup
    And I wait for 2 seconds
    And I tap Save button on File Saving Popup
    And I verify history backup for user <TeamOwner> from Settings is successfully completed
    And I tap Go back to Account navigation button on Settings page
    And I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I accept alert
    And I tap Login button on Welcome page
    And I enter login MyEmail on Login page
    And I enter password MyPassword on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <TeamOwnerEmail>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    When I tap Restore from backup button on First Time overlay
    And I tap Choose Backup File button on the alert
    And I tap Browse button twice on bottom of File Choose Dialog
    And I tap On My iPhone on File Choose Dialog
#    And I sort files by date on File Choose Dialog
    And I tap file containing <Username> in File Choose Dialog
    And I type "<BackupPassword>" text into the alert input field
    And I accept alert
    # wait for backup to import
    And I wait for 9 seconds
    And I perform successful Touch ID
    And I confirm overlay if build has encryption at rest enabled
    Then I see Self profile button on Conversations list page
    #And I do not see conversation <Member2> in conversations list
    And I see Archive button at the bottom of conversations list
    And I see status of conversations list item <Member1> is "Silenced"
    When I open conversation "<Member1>" in conversation list
    Then I see "<Member1> pinged" ping message in the conversation view
    And I see 1 default message in the conversation view
    And I see 1 photo in the conversation view

    Examples:
      | TeamOwner | Username            | Member1   | Member2   | DeviceName1 | DeviceName2 | Picture     | BackupPassword | Password      | Email      | LoginPassword   | TeamName | TeamOwnerEmail |
      | user1Name | user1UniqueUsername | user2Name | user3Name | D1          | D2          | testing.jpg | Gut3nM0rg3n!   | user1Password | user1Email | user1Password   | Chimseys | user1Email     |
