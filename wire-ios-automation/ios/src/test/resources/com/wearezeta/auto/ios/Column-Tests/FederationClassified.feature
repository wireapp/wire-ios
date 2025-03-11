Feature: Federation Classified

  @TC-4941 @col1 @SF.VSNFDLABEL @TSFI.UserInterface @TSFI.Federate @S0.1 @S7 @Security
  Scenario Outline: I should not see classified but unclassified banner in 1:1 conversation with user from unclassified domain when on classified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-3 backend
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<TeamOwner2>" in conversation list
    Then I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation
    When I open conversation details
    Then I see unclassified domain label on Group participant user profile page

    Examples:
      | TeamOwner | TeamName2               | TeamName              | TeamOwner2 |
      | user1Name | The Unclassified Domain | The Classified Domain | user2Name  |

  @TC-4942 @col1 @col3 @SF.VSNFDLABEL @TSFI.UserInterface @TSFI.Federate @S0.1 @S7 @Security
  Scenario Outline: I should not see classified but unclassified banner in 1:1 conversation with user from classified domain when on unclassified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-3 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-1 backend
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    And I enroll the simulator for Touch ID
    And I open column-3 backend deep link in safari
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
    And I am signed in properly
    And I perform successful Touch ID
    When I open conversation "<TeamOwner2>" in conversation list
    Then I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation
    When I open conversation details
    Then I see classified domain label on Group participant user profile page

    Examples:
      | TeamOwner | TeamName2               | TeamName              | TeamOwner2 | Email      | Password        | TeamOwnerEmail |
      | user1Name | The Unclassified Domain | The Classified Domain | user2Name  | user1Email | user1Password   | user1Email     |

  @TC-4980 @col1 @SF.VSNFDLABEL @TSFI.UserInterface @TSFI.Federate @S0.1 @S7 @Security
  Scenario Outline: I should not see classified but unclassified banner in classified group conversation when user from unclassified domain joins
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-3 backend
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <GroupConversationWithClassified> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<GroupConversationWithClassified>" in conversation list
    And I see classified domain label in the conversation
    When I open conversation details
    And I tap Add People button on Group Details page
    And I type search query "<TeamOwner2>" on Group Add People page
    And I select search result item <TeamOwner2> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I close Group Details
    Then I see unclassified domain label in the conversation

    Examples:
      | TeamOwner | TeamName2               | TeamName              | TeamOwner2 | Member1   | Member2   | GroupConversationWithClassified |
      | user1Name | The Unclassified Domain | The Classified Domain | user4Name  | user2Name | user3Name | ClassifiedDomainConvo           |

  @TC-4946 @col1 @SF.VSNFDLABEL @TSFI.UserInterface @TSFI.Federate @S0.1 @S7 @Security
  Scenario Outline: I should not see classified but unclassified banner in ongoing group call when user joins classified conversation from unclassified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-3 backend
    And User <TeamOwner> is me
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> has conversation <ClassifiedGroupConversation> with <Member1>,<Member2> in team <TeamName>
    And <Member1>,<Member2> start 2FA instance using <CallBackend>
    And <Member1>,<Member2> accepts next incoming call automatically
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<ClassifiedGroupConversation>" in conversation list
    And I see classified domain label in the conversation
    And I tap Audio Message button from input tools
    And I accept alert if visible
    When I start a call
    And <Member1>,<Member2> verify that waiting instance status is changed to active in 30 seconds
    And I see Calling overlay
    And I see SECURITY LEVEL: VS-NfD label on calling overlay
    And I tap Minimize button on Calling overlay
    And I open conversation details
    And I tap Add People button on Group Details page
    And I type search query "<TeamOwner2>" on Group Add People page
    When I select search result item <TeamOwner2> on Group Add People page
    And I tap Done keyboard button
    And I close Group Details
    Then I see unclassified domain label in the conversation
    When I restore Calling overlay
    And I see Video Calling overlay
    Then I do not see SECURITY LEVEL: VS-NfD label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName              | TeamName2               | TeamOwner2 | ClassifiedGroupConversation | CallBackend   |
      | user1Name | user2Name | user3Name | The Classified Domain | The UnClassified Domain | user4Name  | classifiedGroupConversation | chrome        |

  @TC-4926 @col1
  Scenario Outline: I want to see the classified banner in classified 1:1 conversation on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-1 backend
    And User <TeamOwner> is connected to <TeamOwner2>
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<TeamOwner2>" in conversation list
    Then I see classified domain label in the conversation
    And I do not see unclassified domain label in the conversation

    Examples:
      | TeamOwner | TeamName2               | TeamName              | TeamOwner2 |
      | user1Name | The Unclassified Domain | The Classified Domain | user2Name  |

  @TC-4927 @col1
  Scenario Outline: I want to see the classified banner in classified group conversation on same domain
    Given There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-1 backend
    And User <TeamOwner2> adds users <Member3>,<Member4> to team <TeamName2> with role Member
    And User <TeamOwner2> is me
    And User <TeamOwner2> has conversation <GroupConversationWithClassifiedOwnDomain> with <Member3>,<Member4> in team <TeamName2>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner2>
    Then I am signed in properly
    When I open conversation "<GroupConversationWithClassifiedOwnDomain>" in conversation list
    Then I see classified domain label in the conversation
    And I do not see unclassified domain label in the conversation

    Examples:
      | TeamName2             | TeamOwner2 | Member3   | Member4   | GroupConversationWithClassifiedOwnDomain |
      | The Classified Domain | user4Name  | user5Name | user6Name | UnclassifiedConvoOnOwnDomain             |

  @TC-4930 @TC-4934 @col1
  Scenario Outline: I want to see the classified banner in incoming connection request from same classified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> is me
    And I enable Federation
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <TeamOwner1> sent connection request to Me
    And I wait for 3 seconds
    And I tap Incoming Pending Requests item in conversations list
    Then I see classified domain icon on the incoming connection page
    # I want to see the unclassified banner in incoming connection request from same unclassified domain - TC-4934
    When I tap Ignore button on Connection Inbox page
    And User <TeamOwner2> sent connection request to Me
    And I wait for 3 seconds
    And I tap Incoming Pending Requests item in conversations list
    Then I do not see classified domain icon on the incoming connection page
    And I see unclassified domain icon on the incoming connection page

    Examples:
      | TeamOwner | TeamOwner2 | TeamOwner1  | TeamName |
      | user1Name | user2Name  | user4Name   | Test     |

  @TC-4931 @TC-4947 @col1 @FS-1762
  Scenario Outline: I want to see the classified banner in outgoing connection request from same classified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    And  I open search screen
    And I type "<TeamOwner2Uniqueusername>" in cleared Search UI input field
    When I tap on conversation <TeamOwner2> in search result
    And I wait for 3 seconds
    And I tap Connect button on Single user Pending outgoing connection page
    Then I see classified domain icon on the outgoing connection page
    # I want to see the unclassified banner in outgoing connection request from an unclassified domain - TC-4947
    When I tap X button on Single user profile page
    And I enter unique username with backend domain of user <TeamOwner1> in cleared Search UI input field
    And I tap on conversation <TeamOwner1> in search result
    Then I do not see classified domain icon on the outgoing connection page
    And I see unclassified domain icon on the outgoing connection page
    #And I see federated title in connection page

    Examples:
      | TeamOwner | TeamOwner2 | TeamOwner1  | TeamName | TeamOwner2Uniqueusername |
      | user1Name | user2Name  | user4Name   | Test     | user2UniqueUsername      |

  @TC-4933 @TC-4932 @col1
  Scenario Outline: I want to see classified banner in group conversation when user from unclassified domain leaves
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-3 backend
    And User <TeamOwner2> adds users <Member3>,<Member4> to team <TeamName2> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> is connected to <TeamOwner2>,<Member3>,<Member4>
    And User <TeamOwner> has conversation <GroupConversationWithUnclassifiedOwnDomain> with <Member3>,<Member4>,<Member1> in team <TeamName>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<GroupConversationWithUnclassifiedOwnDomain>" in conversation list
    And I see unclassified domain label in the conversation
    And I do not see classified domain label in the conversation
    When User <Member3> leaves group chat <GroupConversationWithUnclassifiedOwnDomain>
    And User <Member4> leaves group chat <GroupConversationWithUnclassifiedOwnDomain>
    Then I see classified domain label in the conversation
    And I do not see unclassified domain label in the conversation

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName                | TeamName2             | TeamOwner2 | Member3   | Member4   | GroupConversationWithUnclassifiedOwnDomain |
      | user1Name | user2Name | user3Name | The Unclassified Domain | The Classified Domain | user4Name  | user5Name | user6Name | UnclassifiedConvoOnOwnDomain               |

  @TC-4928 @col1
  Scenario Outline: I want to see the classified banner in incoming/outgoing/ongoing calls in a classified 1:1 conversation on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> is me
    And User <TeamOwner> is connected to <TeamOwner2>
    And All other versions of Wire are uninstalled
    And I enroll the simulator for Touch ID
    And I login to the default email verified backend as <TeamOwner>
    And I am signed in properly
    And I open conversation "<TeamOwner2>" in conversation list
    And <TeamOwner2> starts 2FA instance using <CallBackend>
    And <TeamOwner2> accepts next incoming call automatically
    When I start a call
    And I accept alert if visible
    Then I see SECURITY LEVEL: VS-NfD label on calling overlay
    When <TeamOwner2> verifies that waiting instance status is changed to active in 20 seconds
    And User <TeamOwner2> verifies to send and receive audio
    Then I see Calling overlay
    And I see SECURITY LEVEL: VS-NfD label on calling overlay
    When I tap Leave button on Calling overlay
    And <TeamOwner2> verifies that waiting instance status is changed to destroyed in 40 seconds
    And <TeamOwner2> calls me
    Then I see SECURITY LEVEL: VS-NfD label on calling overlay
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    Then I see SECURITY LEVEL: VS-NfD label on calling overlay

    Examples:
      | TeamOwner | TeamName   | CallBackend | TeamOwner2 |
      | user1Name | Block      | chrome      | user2Name  |

  @TC-4929 @col1
  Scenario Outline: I want to see the classified banner in outgoing/ongoing calls and call participants in a classified group conversation on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner1> adds users <Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <TeamOwner> is connected to <Member2>,<TeamOwner1>
    And User <TeamOwner> has conversation <GroupChat> with <TeamOwner1>,<Member1>,<Member2> in team <TeamName>
    And I open conversation "<GroupChat>" in conversation list
    And <TeamOwner1>,<Member1>,<Member2> starts 2FA instance using <CallBackend>
    And <TeamOwner1>,<Member1>,<Member2> accepts next incoming call automatically
    When I start a call
    And I accept alert if visible
    And I accept alert if visible
    Then I see SECURITY LEVEL: VS-NfD label on calling overlay
    When <TeamOwner1>,<Member1>,<Member2> verifies that waiting instance status is changed to active in 60 seconds
    And I wait for 10 seconds
    Then I see profile picture avatar for users <TeamOwner1>,<Member1>,<Member2> on calling overlay
    When I wait for 3 seconds
    Then I see SECURITY LEVEL: VS-NfD label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName     | TeamOwner1 | GroupChat      | CallBackend  |
      | user1Name | user2Name | user3Name | Stinky Pinky | user4Name  | FederatedGroup | chrome       |

  @TC-4948 @col1
  Scenario Outline: I want to see the classified banner in incoming calls and call participants in a classified group conversation on same domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner1> adds users <Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <TeamOwner> is connected to <Member2>,<TeamOwner1>
    And User <TeamOwner> has conversation <GroupChat> with <TeamOwner1>,<Member1>,<Member2> in team <TeamName>
    And I open conversation "<GroupChat>" in conversation list
    And <TeamOwner1>,<Member1>,<Member2> starts 2FA instance using <CallBackend>
    And <Member1>,<Member2> accepts next incoming call automatically
    When <TeamOwner1> calls <GroupChat>
    Then I see Calling overlay
    And I see SECURITY LEVEL: VS-NfD label on calling overlay
    When I tap Accept button on Calling overlay
    And I accept alert if visible
    And <TeamOwner1> verifies that call status to <GroupChat> is changed to active in 10 seconds
    And <Member1>,<Member2> verifies that waiting instance status is changed to active in 60 seconds
    And User <TeamOwner1>,<Member1>,<Member2> verifies to have 1 peer connection
    Then I see profile picture avatar for users <TeamOwner1>,<Member1>,<Member2> on calling overlay
    Then I see SECURITY LEVEL: VS-NfD label on calling overlay

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName     | TeamOwner1 | GroupChat      | CallBackend  |
      | user1Name | user2Name | user3Name | Stinky Pinky | user4Name  | FederatedGroup | chrome       |

  @TC-4950 @TC-4951 @col1
  Scenario Outline: I want to see the classified banner in 1:1 conversation after accepting incoming connection request from same classified domain
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner> is me
    And I enable Federation
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <TeamOwner1> sent connection request to Me
    And I wait for 3 seconds
    And I tap Incoming Pending Requests item in conversations list
    And I see classified domain icon on the incoming connection page
    When I tap Connect button on Connection Inbox page
    Then I see conversation view page
    And I see classified domain label in the conversation
    # I want to see the classified banner in 1:1 conversation after accepting incoming connection request from unclassified domain - TC-4951
    When I navigate back to conversations list
    And User <TeamOwner2> sent connection request to Me
    And I wait for 3 seconds
    And I tap Incoming Pending Requests item in conversations list
    Then I do not see classified domain icon on the incoming connection page
    When I tap Connect button on Connection Inbox page
    Then I see conversation view page
    And I see unclassified domain label in the conversation

    Examples:
      | TeamOwner | TeamOwner2 | TeamOwner1  | TeamName |
      | user1Name | user2Name  | user4Name   | Test     |