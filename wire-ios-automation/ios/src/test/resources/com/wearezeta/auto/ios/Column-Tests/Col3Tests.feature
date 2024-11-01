Feature: Col 3 Tests

  @TC-6126 @col3
  Scenario Outline: I should be able to copy/paste messages when clipboard is enabled
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceMember1>"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceMember1>"}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
#    And I tap Login button on Welcome page
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And I open conversation "<TeamOwner>" in conversation list
    And User <TeamOwner> sends 1 "<Message1>" message to conversation Myself
    And I see last message in the conversation view is expected message <Message1>
    When I long tap "<Message1>" message in conversation view
    Then I see Copy on edit menu
    And I see Share on edit menu

    Examples:
      | Member1   | TeamOwner | TeamName | DeviceMember1 | Message1 | Email      | Password        | DeviceTeamOwner |
      | user1Name | user2Name | BestTeam | device1       | Hello!   | user1Email | user1Password   | DeviceA         |

  @TC-7638 @TC-7639 @col3
  Scenario Outline: I want to see the VBR toggle is available in settings
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    And User Myself has 1:1 conversation with <Member1> in team <TeamName>
    And <Member1> starts 2FA instance using <CallBackend>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <TeamOwnerEmail>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    When I open Self profile
    And I open settings screen
    And I select settings item Options
    Then I see the text on VBR toggle in settings
    And I verify the value of settings item Variable Bit Rate Encoding equals to "<ExpectedValue>"
    # I should not be able to see CBR label in calling if my VBR toggle is ON - TC-7639
    When I tap X navigation button on Settings page
    And I open conversation "<Member1>" in conversation list
    And <Member1> calls me
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    And <Member1> verifies that call status to me is changed to active in 20 seconds
    And User <Member1> verifies to have 1 peer connection
    And User <Member1> verifies to have CBR connection
    And I wait for 7 seconds
    Then I do not see call indicator VARIABLE BIT RATE
    When User <Member1> switches video on
    And User <Member1> verifies to have CBR connection
    And I wait for 7 seconds
    Then I do not see call indicator VARIABLE BIT RATE

    Examples:
      | TeamOwner | Member1   | CallBackend | Email      | Password        | TeamName       | TeamOwnerEmail | ExpectedValue |
      | user1Name | user2Name | zcall_v3    | user1Email | user1Password   | Do You Read me | user1Email     | 1             |

  @TC-7640 @col3 @cbr
  Scenario Outline: I want to verify that there is no CBR traffic after receiving 1:1 audio and video call using <CallBackend>
    Given I allow microphone access
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    And <Member1> starts 2FA instance using <CallBackend>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <TeamOwnerEmail>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And I open conversation "<Member1>" in conversation list
    When <Member1> calls me
    And I tap Accept button on Calling overlay
    And <Member1> verifies that call status to me is changed to active in 20 seconds
    And User <Member1> verifies to have CBR connection
    Then I do not see call indicator CONSTANT BIT RATE
    When User <Member1> switches video on
    And User <Member1> verifies to have CBR connection
    Then I do not see call indicator CONSTANT BIT RATE

    Examples:
      | TeamOwner | Member1   | CallBackend | Email      | Password        | TeamName   | TeamOwnerEmail |
      | user1Name | user2Name | chrome      | user1Email | user1Password   | Top Secret | user1Email     |

  @TC-7637 @col3
  Scenario Outline: I want to verify opening gallery tapping on gallery icon in col3 builds
    Given I allow access to all photos
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And I open conversation "<TeamOwner>" in conversation list
    When I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I tap Camera Roll button on Keyboard Gallery overlay
    And I select a picture from Camera Roll
    And I tap Confirm button on Picture preview page
    Then I see 1 photo in the conversation view
    When I type the default message and send it
    And I wait for 2 seconds
    Then I see 1 default message in the conversation view

    Examples:
      | TeamOwner | Member1   | TeamName | Email      | Password        | DeviceName |
      | user1Name | user2Name | Zikzak   | user2Email | user2Password   | device1    |

  @TC-7636 @col3
  Scenario Outline: I want to verify that file sharing is enabled in bund col 3 builds
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}]}
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    When I open conversation "<TeamOwner>" in conversation list
    Then I see Add Picture button in input tools palette
    And I see Sketch button in input tools palette
    And I see Giphy button in input tools palette
    And I see Audio Message button in input tools palette
    And I see File Transfer button in input tools palette
    And I see Video Message button in input tools palette
    When User <TeamOwner> sends 1 image file testing.jpg to conversation <Member1>
    Then I see 1 photo in the conversation view
    When I long tap on image in conversation view
    Then I see Save on edit menu
    And I see Share on edit menu
    And I see Copy on edit menu
    And I see Reply on edit menu
    And I see menu with quick reactions and other items
    And I see Delete on edit menu
    When I tap on ❤️ reaction in quick reactions
    And I wait for 2 seconds
    Then I see 1 photo in the conversation view
  # Enable share extension
    When I navigate back to conversations list
    And I open Safari with url "<URL>"
    And I tap Share button in Safari
    #And I tap More button on share extension
    #And I enable Wire in share extension
    #And I tap Done in share extension
    And I tap Wire Bund in share extension
    And I wait for 3 seconds
    And I tap Choose in share extension
    And I wait for 3 seconds
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I select conversation "<TeamOwner>" in share extension
    And I tap Send button in share extension
    Then I do not see alert contains text "File sharing restrictions"
    When I restore Wire
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I open conversation "<TeamOwner>" in conversation list
    And I wait for 2 seconds
    Then I see last message in the conversation view contains expected message <Text>

    Examples:
      | Member1   | TeamOwner | TeamName     | DeviceName | Email      | Password        | URL                        | Text        |
      | user1Name | user2Name | File sharing | device1    | user1Email | user1Password   | https://www.duckduckgo.com | duckduckgo  |

  @TC-8187 @TC-8188 @col3
  Scenario Outline: I should not see classified but unclassified banner in group conversation when self user is on unclassified domain and all participants are on classified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-1 backend
    And User <TeamOwner2> adds users <Member3>,<Member4> to team <TeamName2> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> is connected to <TeamOwner2>,<Member3>,<Member4>
    And User <TeamOwner> has conversation <GroupConversationWithClassified> with <TeamOwner2>,<Member3>,<Member4> in team <TeamName>
    And User <TeamOwner> has conversation <GroupConversationWithUnclassifiedOwnDomain> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I open default backend via deep link in safari
    And I wait for 3 seconds
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I perform successful Touch ID
    And I accept First Time overlay
    And I am signed in properly
    When I open conversation "<GroupConversationWithClassified>" in conversation list
    Then I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation
    # C1266662 -- I should not see classified but unclassified banner in group conversation when on unclassified domain and participants are only from same unclassified domain
    When I navigate back to conversations list
    And I open conversation "<GroupConversationWithUnclassifiedOwnDomain>" in conversation list
    Then I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName                | TeamName2             | TeamOwner2 | Member3   | Member4   | GroupConversationWithClassified | GroupConversationWithUnclassifiedOwnDomain | Email      | Password        |
      | user1Name | user2Name | user3Name | The Unclassified Domain | The Classified Domain | user4Name  | user5Name | user6Name | UnClassifiedConvoWithClassified | UnclassifiedConvoOnOwnDomain               | user1Email | user1Password   |

  @TC-8189 @col3
  Scenario Outline: I should not see classified but unclassified banner in 1:1 conversation with user from classified domain when on unclassified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-1 backend
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    And I open column-3 backend deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I perform successful Touch ID
    And I accept First Time overlay
    And I am signed in properly
    When I open conversation "<TeamOwner2>" in conversation list
    Then I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation

    Examples:
      | TeamOwner | TeamName2             | TeamName                | TeamOwner2 | Email      | Password        |
      | user1Name | The Classified Domain | The UnClassified Domain | user2Name  | user1Email | user1Password   |

  @TC-8190 @col3
  Scenario Outline: I should not see classified but unclassified banner in group call when self user is on unclassified domain and all participants are on classified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-1 backend
    And User <TeamOwner2> adds users <Member3>,<Member4> to team <TeamName2> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> is connected to <TeamOwner2>,<Member3>,<Member4>
    And User <TeamOwner> has conversation <GroupConversationWithClassified> with <TeamOwner2>,<Member3>,<Member4>,<Member1>,<Member2> in team <TeamName>
    And <TeamOwner2>,<Member3> starts 2FA instance using <CallBackend>
    And <TeamOwner2>,<Member3> accepts next incoming call automatically
    And All other versions of Wire are uninstalled
    And I open column-3 backend deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I perform successful Touch ID
    And I accept First Time overlay
    And I am signed in properly
    And I open conversation "<GroupConversationWithClassified>" in conversation list
    And I tap Audio Message button from input tools
    And I accept alert
    And I tap Audio Call button
    And I accept alert
    And <TeamOwner2>,<Member3> verify that waiting instance status is changed to active in 30 seconds
    When I see Calling overlay
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    And I do not see SECURITY LEVEL: VS-NfD label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName                | TeamName2             | TeamOwner2 | Member3   | Member4   | GroupConversationWithClassified  | CallBackend   | Email      | Password        |
      | user1Name | user2Name | user3Name | The Unclassified Domain | The Classified Domain | user4Name  | user5Name | user6Name | UnClassifiedConvoWithClassified  | chrome        | user1Email | user1Password   |

  @TC-8191 @col3
  Scenario Outline: I should not see classified but unclassified banner in group call when on unclassified domain and participants are only from same unclassified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <GroupConversationWithOwnUnclassifiedOwnDomain> with <Member1>,<Member2> in team <TeamName>
    And <Member1>,<Member2> starts 2FA instance using <CallBackend>
    And <Member1>,<Member2> accepts next incoming call automatically
    And All other versions of Wire are uninstalled
    And I open column-3 backend deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I perform successful Touch ID
    And I accept First Time overlay
    And I am signed in properly
    And I open conversation "<GroupConversationWithOwnUnclassifiedOwnDomain>" in conversation list
    And I tap Audio Message button from input tools
    And I accept alert
    And I tap Audio Call button
    And <Member1>,<Member2> verify that waiting instance status is changed to active in 30 seconds
    When I see Calling overlay
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    And I do not see SECURITY LEVEL: VS-NfD label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName                | TeamName2             | TeamOwner2 | Member3   | Member4   | GroupConversationWithOwnUnclassifiedOwnDomain | CallBackend   | Email      | Password        |
      | user1Name | user2Name | user3Name | The Unclassified Domain | The Classified Domain | user4Name  | user5Name | user6Name | UnclassifiedConvoOnOwnDomain                  | chrome        | user1Email | user1Password   |

  @C1266658 @col3
  Scenario Outline: I want to see the unclassified banner in unclassified 1:1 conversation on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-3 backend
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    When I open conversation "<TeamOwner2>" in conversation list
    Then I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation

    Examples:
      | TeamOwner | TeamName2               | TeamName                | TeamOwner2 | Email      | Password        |
      | user1Name | The Unclassified Domain | The Unclassified Domain | user2Name  | user1Email | user1Password   |

  @C1266657 @col3
  Scenario Outline: I want to see the unclassified banner in outgoing connection request from same unclassified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> is me
    And I enable Federation
    And All other versions of Wire are uninstalled
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    When I open search screen
    And I type "<TeamOwner2Uniqueusername>" in cleared Search UI input field
    When I tap on conversation <TeamOwner2> in search result
    And I wait for 3 seconds
    And I tap Connect button on Single user Pending outgoing connection page
    Then I see unclassified domain icon on the outgoing connection page

    Examples:
      | TeamOwner | TeamOwner2 | TeamName | Email      | Password        | TeamOwner2Uniqueusername |
      | user1Name | user2Name  | Test     | user1Email | user1Password   | user2UniqueUsername      |

  @C1266660 @col3
  Scenario Outline: I want to see the unclassified banner in unclassified outgoing group call on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner1> adds users <Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And User <TeamOwner> is connected to <Member2>,<TeamOwner1>
    And User <TeamOwner> has conversation <GroupChat> with <TeamOwner1>,<Member1>,<Member2> in team <TeamName>
    And I open conversation "<GroupChat>" in conversation list
    And <TeamOwner1>,<Member1>,<Member2> starts 2FA instance using <CallBackend>
    And <TeamOwner1>,<Member1>,<Member2> accepts next incoming call automatically
    When I tap Audio Call button
    And I accept alert if visible
    And I accept alert if visible
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    When <TeamOwner1>,<Member1>,<Member2> verifies that waiting instance status is changed to active in 60 seconds
    And I wait for 10 seconds
    Then I see profile picture avatar for users <TeamOwner1>,<Member1>,<Member2> on calling overlay
    When I wait for 3 seconds
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName     | TeamOwner1 | GroupChat      | CallBackend  | Email      | Password        |
      | user1Name | user2Name | user3Name | Stinky Pinky | user4Name  | FederatedGroup | chrome       | user1Email | user1Password   |

  @C1266708 @col3
  Scenario Outline: I want to see the unclassified banner in unclassified incoming group call on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner1> adds users <Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And User <TeamOwner> is connected to <Member2>,<TeamOwner1>
    And User <TeamOwner> has conversation <GroupChat> with <TeamOwner1>,<Member1>,<Member2> in team <TeamName>
    And I open conversation "<GroupChat>" in conversation list
    And <TeamOwner1>,<Member1>,<Member2> starts 2FA instance using <CallBackend>
    And <Member1>,<Member2> accepts next incoming call automatically
    When <TeamOwner1> calls <GroupChat>
    Then I see Calling overlay
    And I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    When I tap Accept button on Calling overlay
    And I accept alert if visible
    And <TeamOwner1> verifies that call status to <GroupChat> is changed to active in 10 seconds
    And <Member1>,<Member2> verifies that waiting instance status is changed to active in 60 seconds
    And User <TeamOwner1>,<Member1>,<Member2> verifies to have 1 peer connection
    Then I see profile picture avatar for users <TeamOwner1>,<Member1>,<Member2> on calling overlay
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName     | TeamOwner1 | GroupChat      | CallBackend  | Email      | Password        |
      | user1Name | user2Name | user3Name | Stinky Pinky | user4Name  | FederatedGroup | chrome       | user1Email | user1Password   |

  @C1266659 @col3
  Scenario Outline: I want to see the unclassified banner in unclassified incoming/ongoing/outgoing 1:1 call on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> is me
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> has 1:1 conversation with <TeamOwner2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And I open conversation "<TeamOwner2>" in conversation list
    And <TeamOwner2> starts 2FA instance using <CallBackend>
    And <TeamOwner2> accepts next incoming call automatically
    When I tap Audio Call button
    And I accept alert if visible
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    When <TeamOwner2> verifies that waiting instance status is changed to active in 20 seconds
    And User <TeamOwner2> verifies to send and receive audio
    Then I see Calling overlay
    And I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    When I tap Leave button on Calling overlay
    And I wait for 3 seconds
    And <TeamOwner2> calls me
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    Then I see SECURITY LEVEL: UNCLASSIFIED label on calling overlay

    Examples:
      | TeamOwner      | Member1      | TeamName   | CallBackend | Email      | Password        | TeamOwner2 |
      | user1Name      | user2Name    | Block      | chrome      | user1Email | user1Password   | user3Name  |

  @C1294772 @connect
  Scenario Outline: I want to be connected to a user when both users have connection requests out to each other on col 3
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> is me
    And I enable Federation
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I accept alert if visible
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I wait for 3 seconds
    And I see Encryption At Rest overlay
    And I type bla on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    And I am signed in properly
    When I open search screen
    And I type "<TeamOwner2Uniqueusername>" in cleared Search UI input field
    When I tap on conversation <TeamOwner2> in search result
    And User <TeamOwner2> sent connection request to Me
    And I tap Connect button on Single user Pending outgoing connection page
    And I tap X button on Single user Pending outgoing connection page
    And I tap on conversation <TeamOwner2> in search result
    Then I see the input field

    Examples:
      | TeamOwner | TeamOwner2 | TeamName | Email      | Password        | TeamOwner2Uniqueusername |
      | user1Name | user2Name  | Test     | user1Email | user1Password   | user2UniqueUsername      |
