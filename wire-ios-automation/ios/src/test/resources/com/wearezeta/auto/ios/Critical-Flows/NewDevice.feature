Feature: New Device

  # TODO - add stuff around the device verification and removing device to finish if deemed needed
  # TODO - Fix the done button in webview
   # TODO - failing due to not cleaning up simulators, fix incoming
  @unstable
  #Flow 4 - Employee is setting up new device after old device lost
  Scenario Outline: Employee setting up new device after loosing old device
    #Employee is part of a team, with at least one other member
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
  #Employee has multiple devices
    #(TBD: timing out) And User adds the following device: {"<Member1>": [{"name": "Device1"}]} and might not be necessary
  #Employee logs in to Wire and records current device thumbprint
    And I tap Login button on Welcome page
    And I sign in user <Member1> with email
    And I accept First Time overlay
    And I accept alert if visible
    And I open settings screen
    And I select settings item Devices
    And I save the device id of the current device
    And I tap Go back to Settings navigation button on Settings page
    And I tap X navigation button on Settings page
  #Employee sends a message to the other member
    And I open conversation "<Member2>" in conversation list
    And I tap on text input
    When I type the <Text> message
    And I tap Send Message button in conversation view
  #Employee makes a backup
    And I navigate back to conversations list
    And I open settings screen
    And I select settings item Account
    And I select settings item Back Up Conversations
    When I initiate history backup from Settings
    And I type password "<BackupPassword>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I tap Save to Files button on File Saving Popup
    When I tap Save button on File Saving Popup
    When I tap Go back to Account navigation button on Settings page
  #Reset device
    And I reset Wire
    And I wait for 2 seconds
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I tap Login button on Welcome page
    And I sign in user <Member1> with email
  #Employee imports backup
    When I tap Restore from backup button on First Time overlay
    And I tap Choose Backup File button on the alert
    And I tap Browse button twice on bottom of File Choose Dialog
    And I tap On My iPhone on File Choose Dialog
    And I tap file containing user1UniqueUsername in File Choose Dialog
    And I type "<BackupPassword>" text into the alert input field
  # wait for backup to import
    And I wait for 5 seconds
    And I accept alert
    And I accept alert if visible
  #Employee can see the message to the other member and send another
    And I open conversation "<Member2>" in conversation list
    And I see last message in the conversation view is expected message <Text>
    And I tap on text input
    When I type the <Text2> message
    And I tap Send Message button in conversation view
    Then I see last message in the conversation view is expected message <Text2>
    When I navigate back to conversations list
  # Employee resets their password, but not really because hard to do via this
    And I open settings screen
    And I select settings item Account
    #TODO: Figure out why done button isn't being clicked
    #And I select settings item Reset Password
    #Then I see "Change Password" web page
    #When I tap Done Button on web view
    When I tap Go back to Settings navigation button on Settings page
  # Employee removes lost device
    And I select settings item Devices
    And I open my remembered device
    And I tap Remove Device button on Device Details page
    And I confirm with my <BackupPassword> the deletion of the device on Settings page
    Then I see 1 device is shown on Settings page
  # Employee verifies other device
    # TBD and maybe not necessary

    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | BackupPassword | Text | Text2 |
      | user1Name | user3Name | SuperTeam | user2Name | Aqa123456!     | Hi   | Text  |
