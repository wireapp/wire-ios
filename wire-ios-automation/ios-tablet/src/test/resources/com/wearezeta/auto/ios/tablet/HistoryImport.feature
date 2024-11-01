Feature: History Import

  @C669489 @regression @landscape
  Scenario Outline: I want to import backup and see my exported messages in a conversation [LANDSCAPE]
    Given There are personal account users <Name>,<Contact1>
    And User <Name> is me
    And User Myself is connected to <Contact1>
    And User adds the following device: {"<Contact1>": [{"name": "<DeviceName1>"}]}
    And I tap Login button on Welcome page
    And I Sign in on tablet using my email
    And I accept First Time overlay
    And I am signed in properly
    And I accept Help us make Wire better popup
    And User <Contact1> sends 1 image file <Picture> to conversation Myself
    And User <Contact1> sends 1 default message to conversation Myself
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Back Up Conversations
    And I initiate history backup from Settings
    And I type password "<Password>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I see correct name of backup file for user <Name> on File Saving Popup
    And I tap Save to Files button on File Saving Popup
    And I tap On My iPad on File Saving Popup
    And I tap Save button on File Saving Popup
    And I verify history backup for user <Name> from Settings is successfully completed
    And User Myself removes all their registered OTR clients
    # Session expired
    And I accept alert
    And I see Welcome page
    And I tap Login button on Welcome page
    And I enter login MyEmail on Login page
    And I enter password MyPassword on Login page
    And I tap Login button on Login page
    When I tap Restore from backup button on First Time overlay
    And I tap Choose Backup File button on the alert
    And I tap Browse button of File Choose Dialog on iPad
    And I tap On My iPad on File Choose Dialog
    And I tap file containing <Username> in File Choose Dialog
    And I type "<Password>" text into the alert input field
    And I accept alert
    And I accept alert
    Then I see Self profile button on Conversations list page
    When I open conversation "<Contact1>" in conversation list
    Then I see 1 default message in the conversation view
    And I see 1 photo in the conversation view

    Examples:
      | Name      | Contact1  | DeviceName1 | Picture     | Password     |  Username            |
      | user1Name | user2Name | D1          | testing.jpg | Gut3nM0rg3n! |  user1UniqueUsername |
