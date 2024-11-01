Feature: Legal Hold

  ##########################
  #      Verification      #
  ##########################

  @C758423 @regression @legalHold @landscape
  Scenario Outline: I want to verify all my devices on the legal hold dialog from conversation list
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User adds the following device: {"<Member1>": [{"name": "<DeviceName>"}]}
    And Admin user <TeamOwner> sends Legal Hold request for user <Member1>
    And User <TeamOwner> has conversation <ConversationName> with <Member1>, <Member2> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    # Accept LH Alert
    And I wait up until 10 seconds until alert is visible
    And I type "<Password>" text into the alert input field
    And I tap Accept button on the alert
    And I see legal hold indicator next to self title in Conversation list
    And I tap the legal hold indicator next to self title in Conversation list
    And I see Legal hold overview page
    And I see Myself as a legal hold subject on Legal hold overview page
    And I tap legal hold subject <Member1> on Legal hold overview page
    And I see legal hold device as first item on Devices tab
    And I see the label Not Verified is shown on user details page for the device number 1
    And I open details page of device number 1 on Devices tab
    When I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    Then I see the label Verified is shown on user details page for the device number 1
    When I open details page of device number 2 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    Then I see the label Verified is shown on user details page for the device number 2

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName  | ConversationName | DeviceName | Password      |
      | user1Name | user2Name | user3Name | SuperTeam | GroupChat        | device2    | user1Password |


  ##########################
  #  Detect Legal Hold On #
  ##########################

  @C758427 @regression @legalHold @landscape
  Scenario Outline: I want to detect legal hold and see no warning when I send certain messages (delete, like, read receipt, delivery receipt)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And User <Member2> sends 1 "<Message>" message under legal hold to conversation <Member1>
    # Send delivery + read receipt
    When I open conversation "<Member2>" in conversation list
    Then I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldEnabled>" system message in the conversation view
    And I do not see alert contains text "<LegalHoldEnabledAlert>"
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
      #Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
      # Like
    And I tap Like icon in the conversation
    Then I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldEnabled>" system message in the conversation view
    And I do not see alert contains text "<LegalHoldEnabledAlert>"
    And I see Unlike icon in the conversation
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
      #Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And I type the default message and send it
    And User <Member2> accepts pending Legal Hold request
      # Delete message
    And I long tap default message in conversation view
    And I tap on Delete on edit menu
    And I select Delete for Everyone item from Delete menu
    Then I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldEnabled>" system message in the conversation view
    And I do not see alert contains text "<LegalHoldEnabledAlert>"

    Examples:
      | TeamOwner | TeamName  | Member1   | Member2   | Message           | LegalHoldEnabled                      | LegalHoldEnabledAlert                         | LegalHoldDisabled      |
      | user1Name | boudewijn | user2Name | user3Name | getting the ropes | This conversation is under legal hold | The conversation is now subject to legal hold | Legal Hold deactivated |

  @C758428 @unstable @legalHold @filetransfer @landscape
  Scenario Outline: I want to detect legal hold and see a warning when I send certain messages (text, files, audio, video, image, edit, reply, ping)
      # This test is flaky because of the lenght. Consider splitting it up in multiple?
    Given I allow camera access
    And I allow access to all photos
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <Member1> is me
    And I prepare <FileName> to be uploaded as a video message
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And Users add the following devices: {"<Member1>": [{"name" : "<DeviceName>"}]}
    And I sign in user <Member1> with fast login
    And I open conversation "<Member2>" in conversation list
    And User <Member2> sends 1 "<Message>" message to conversation <Member1>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    # Send file/pct
    When I tap File Transfer button from input tools
    And I tap file transfer option for 80 MB file
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    And I see Cancel button on the alert
    And I see Send Anyway button on the alert
    And I see What Is Legal Hold? button on the alert
    When I tap Send Anyway button on the alert
    Then I see file transfer placeholder
    And I see legal hold indicator next to conversation title in conversation view
    Then I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    # Edit message yes
    And I type the "<Message>" message and send it
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I long tap "<Message>" message in conversation view
    And I tap on Edit on edit menu
    And I type the "<EditMessage>" message
    And I tap Confirm button on Edit control
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    Then I see last message in the conversation view is expected message <Message><EditMessage>
    And I do not see message details Sending failed in message toolbox
    And I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And I scroll to the bottom of the conversation
    # Audio message yes
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I tap Audio Message button from input tools
    And I accept alert if visible
    And I tap Audio Message button from input tools
    And I long tap Audio Message button from input tools
    And I tap Send record control button
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    And I scroll to the bottom of the conversation
    Then I see audio message container in the conversation view
    And I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And I scroll to the bottom of the conversation
    # Text message yes
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I type the "<Message>" message and send it
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    Then I see last message in the conversation view is expected message <Message>
    And I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And I scroll to the bottom of the conversation
    # Video message yes
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I tap Video Message button from input tools
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    And I scroll to the bottom of the conversation
    Then I see video message container in the conversation view
    And I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And I scroll to the bottom of the conversation
    # Image yes
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I select the first item from Keyboard Gallery
    And I tap Confirm button on Picture preview page
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    And I scroll to the bottom of the conversation
    Then I see 1 photo in the conversation view
    And I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    # Ping
    And I tap Ping button from input tools
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    And I scroll to the bottom of the conversation
    Then I see legal hold indicator next to conversation title in conversation view
    And I see "You pinged" ping message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldDisabled>" system message in the conversation view
    # Reset conversation view
    And User <Member2> sends 4 long messages to conversation <Member1>
    And I scroll to the bottom of the conversation
    # Reply yes
    And User <Member1> sends message "<Message>" as reply to last message of conversation <Member2> via device <DeviceName>
    And I long tap "<Message>" message in conversation view
    And I tap on Reply on edit menu
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I type the "<Message>" message and send it
    Then I see alert contains text "<LegalHoldEnabledAlert>"
    When I tap Send Anyway button on the alert
    And I scroll to the bottom of the conversation
    Then I see the last message in conversation view contains a reply
    And I see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldActivated>" system message in the conversation view

    Examples:
      | TeamOwner | TeamName  | Member1   | Member2   | Message           | ItemName           | EditMessage  | LegalHoldEnabledAlert                         | LegalHoldDisabled      | FileName     | DeviceName     | LegalHoldActivated                    |
      | user1Name | boudewijn | user2Name | user3Name | getting the ropes | CountryCodes.plist | rope dropped | The conversation is now subject to legal hold | Legal Hold deactivated | testing.mp4  | Contact1Device | This conversation is under legal hold |

  ##########################
  #  Detect Legal Hold Off #
  ##########################

  @C758420 @knownbug @legalHold @landscape
  Scenario Outline: I want to detect legal hold is off when I tap on the indicator after the subject leaves the conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <ConversationName> with <Member1>, <Member2> in team <TeamName>
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <Member1> is me
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I sign in user <Member1> with fast login
    And I open conversation "<ConversationName>" in conversation list
    And User <TeamOwner> sends 1 default message under legal hold to conversation <ConversationName>
    And I see "<LegalHoldActivated>" system message in the conversation view
    And I open group conversation details
    When User <Member2> leaves group chat <ConversationName>
    Then I do not see legal hold indicator on Group Details page
    When I tap X button on Group Details page
    Then I do not see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldDeactivated>" system message in the conversation view

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName  | ConversationName | LegalHoldDeactivated                         | LegalHoldActivated                    |
      | user1Name | user2Name | user3Name | SuperTeam | GroupChat        | Legal hold deactivated for this conversation | This Conversation is under legal hold |

  @C758421 @regression @legalHold @landscape
  Scenario Outline: I want to detect legal hold is off when others send a message
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I sign in user <Member1> with fast login
    And I open conversation "<Member2>" in conversation list
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldActivated>" system message in the conversation view
    And I see legal hold indicator next to conversation title in conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And User <Member2> sends 1 default message to conversation <Member1>
    Then I do not see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldDeactivated>" system message in the conversation view

    Examples:
      | TeamOwner | TeamName  | Member1   | Member2   | LegalHoldActivated                    | LegalHoldDeactivated                         |
      | user1Name | boudewijn | user2Name | user3Name | This conversation is under legal hold | Legal hold deactivated for this conversation |

  @C758422 @regression @legalHold @landscape
  Scenario Outline: I want to detect legal hold is off when I send a message
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <Member1> is me
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And User <Member2> accepts pending Legal Hold request
    And I sign in user <Member1> with fast login
    And I open conversation "<Member2>" in conversation list
    And User <Member2> sends 1 default message to conversation <Member1>
    And I see "<LegalHoldActivated>" system message in the conversation view
    When Admin user <TeamOwner> turns off Legal Hold for user <Member2>
    And I type the default message and send it
    Then I do not see legal hold indicator next to conversation title in conversation view
    And I see "<LegalHoldDeactivated>" system message in the conversation view

    Examples:
      | TeamOwner | TeamName  | Member1   | Member2   | LegalHoldActivated                    | LegalHoldDeactivated   |
      | user1Name | boudewijn | user2Name | user3Name | This conversation is under legal hold | Legal hold deactivated |

  ###############################
  #      Subject - Dialog       #
  ###############################

  @C758433 @regression @legalHold @landscape
  Scenario Outline: I want to be informed when admin turn on legal hold for me and accept it while I am on the conversation list
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And I sign in user <Member1> with fast login
    And I see conversations list
    When Admin user <TeamOwner> sends Legal Hold request for user <Member1>
    Then I see alert contains text "<LegalHoldAlert>"
    When I type "<Password>" text into the alert input field
    And I tap Accept button on the alert
    Then I see legal hold indicator next to self title in Conversation list

    Examples:
      | TeamOwner | TeamName  | Member1   | Password      | ConversationName | LegalHoldAlert       |
      | user1Name | Pikka Pea | user2Name | user2Password | Whats that       | Legal Hold Requested |

  ##################################
  #      Subject - Indicator       #
  ##################################

  @C758432 @regression @legalHold @landscape
  Scenario Outline: I want to see legal hold indicator on conversation when sharing messages
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <TeamOwner> has conversation <ConversationName> with <Member1>, <Member2> in team <TeamName>
    And User <Member1> is me
    And User adds the following device: {"<Member2>": [{"name": "<DeviceName>"}]}
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And Admin user <TeamOwner> sends Legal Hold request for user <Member1>
    And User <Member1> accepts pending Legal Hold request
    And I sign in user <Member1> with fast login
     # Accept LH alert
    And I wait up until 10 seconds until alert is visible
    And I accept alert
    And I open group conversation "<ConversationName>" in conversation list
    And I type the default message and send it
    And I long tap default message in conversation view
    When I tap on Share on edit menu
    Then I see legal hold indicator on Forward page

    Examples:
      | TeamOwner | TeamName    | Member1   | Member2   | ConversationName |
      | user1Name | Pied Piper  | user2Name | user3Name | Pied Piper Inc   |

  ##################################
  #  Subject - Indicator Overview  #
  ##################################

  @C758431 @regression @legalHold @landscape
  Scenario Outline: I want to see others device details page with correct order and UI elements when I tap on other legal hold user on legal hold overview page
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> adds user <Partner1> to team <TeamName> with role Partner
    And User adds the following device: {"<Member2>": [{"name": "<DeviceName>"}]}
    And User <TeamOwner> has conversation <ConversationName> with <Member1>, <Member2>, <Partner1> in team <TeamName>
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And Admin user <TeamOwner> sends Legal Hold request for user <Member2>
    And Admin user <TeamOwner> sends Legal Hold request for user <Partner1>
    And User <Member2> accepts pending Legal Hold request
    And User <Partner1> accepts pending Legal Hold request
    And Admin user <TeamOwner> sends Legal Hold request for user <Member1>
    And I type "<Password>" text into the alert input field
    And I accept alert
    And I see legal hold indicator on Group Details page
    And I tap legal hold indicator on Group Details page
    And I see Legal hold overview page
    And I see Myself as a legal hold subject on Legal hold overview page
    And I see legal hold subjects <Member2>,<Partner1> on Legal hold overview page
    When I tap legal hold subject <Member2> on Legal hold overview page
    Then I see legal hold device as first item on Devices tab
    And I see 2 items are shown on Devices tab
    When I tap Back button on Single user profile page
    And I tap close button legal hold overview page
    Then I see legal hold indicator on Group Details page

    Examples:
      | Member1   | Member2   | TeamOwner | Partner1  | TeamName  | ConversationName | DeviceName | Password      |
      | user1Name | user2Name | user3Name | user4Name | SuperTeam | GroupChat        | device2    | user1Password |

  @C758430 @regression @legalHold @landscape
  Scenario Outline: I want to see legal hold overview page with explanation, show my own finger print when I tap on the legal hold indicator next to my name on the conversation list
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> registers legal hold service with team "<TeamName>"
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And Admin user <TeamOwner> sends Legal Hold request for user <Member1>
    And I see alert contains text "<LegalHoldAlert>"
    And I type "<Password>" text into the alert input field
    And I accept alert
    When I tap the legal hold indicator next to self title in Conversation list
    Then I see Legal hold overview page
    And I see Myself as a legal hold subject on Legal hold overview page
    And I do not see legal hold subject <TeamOwner> on Legal hold overview page
    When I tap close button legal hold overview page
    Then I see conversations list

    Examples:
      | TeamOwner | TeamName  | Member1   | LegalHoldAlert       | Password      |
      | user1Name | Pikka Pea | user2Name | Legal Hold Requested | user1Password |
