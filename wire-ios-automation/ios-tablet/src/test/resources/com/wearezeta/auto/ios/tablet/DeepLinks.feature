Feature: Deep Links

  #########################
  #      Conversation     #
  #########################

  @C749884 @C749880 @deeplinks @regression @landscape
  Scenario Outline: I want to see the conversation when I am in it (conversation was not archived) tap on deeplink outside of wire
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And I minimize Wire
    # Last page: conversation list
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I accept notification permission alert if visible
    And I open group conversation details
    Then I see conversation name "<TeamGroup>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup |
      | user1Name | Super club | user2Name | user3Name | Ramen     |

  @C749885 @C749881 @deeplinks @regression @landscape
  Scenario Outline: I want to see the conversation when I am in it (conversation was archived)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User Myself archives conversation <TeamGroup>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I do not see conversation <TeamGroup> in conversations list
    And I open 1:1 conversation "<TeamOwner>" in conversation list
    When User <TeamOwner> sends deep link for conversation <TeamGroup> to conversation Myself
    And I tap at deep link message
    And I accept alert
     # Opening the safari and then opening the app, it takes sometime and due to delay tests can fail so I put wait here
    And I wait for 3 seconds
    And I accept notification permission alert if visible
    And I open group conversation details
    Then I see conversation name "<TeamGroup>" on Group Details page
    And I swipe up on Group Details page
      # Last page: participant profile
    And I select participant <TeamOwner> on Group Details page
    And I minimize Wire
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I accept notification permission alert if visible
    And I open group conversation details
    Then I see conversation name "<TeamGroup>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup |
      | user1Name | Super club | user2Name | user3Name | Ramen     |

  @C749883 @deeplinks @regression @landscape
  Scenario Outline: I want to see an error when I am not in the conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    # Team Group which I am not in
    And User <TeamOwner> has conversation <TeamGroup> with <Member2> in team <TeamName>
    And There are personal account users <User3>,<User4>,<User5>
    And User <User3> is connected to Myself, <User4>, <User5>
    # Personal Group which I am not in
    And User <User3> has group conversation <PersonalGroup> with <User4>, <User5>
    And I sign in user <Member1> with fast login
    And I open 1:1 conversation "<User3>" in conversation list
    And I minimize Wire
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I accept notification permission alert if visible
    Then I see alert contains text "<ExpectedAlertBody>"
    And I accept alert if visible
    When User <User3> sends deep link for conversation <PersonalGroup> to conversation Myself
    And I tap at deep link message
    And I accept alert
    Then I see alert contains text "<ExpectedAlertBody>"

    Examples:
      | TeamOwner | TeamName | Member1   | Member2   | User3     | User4     | User5     | TeamGroup   | PersonalGroup | ExpectedAlertBody                                                               |
      | user1Name | Mad Men  | user2Name | user3Name | user4Name | user5Name | user6Name | Don or Dick | Bad ad        | You may not have permission with this account or the person may not be on Wire. |

  @C749891 @deeplinks @regression @landscape
  Scenario Outline: I want to see an error message when I am on Welcome page
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And I minimize Wire
    # Last page: Welcome page
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I wait up until 3 seconds until alert is visible
    Then I see alert contains text "<ExpectedAlertBody>"
    And I see alert contains text "<ExpectedAlertTitle>"

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup | ExpectedAlertBody  | ExpectedAlertTitle      |
      | user1Name | Super club | user2Name | user3Name | Ramen     | You need to log in | Authorization required. |

  @C749887 @deeplinks @regression @landscape
  Scenario Outline: I want to see an error message on a link with broken part after wire://
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And I minimize Wire
    When I open Safari with url "<BrokenDeepLink>"
    And I accept notification permission alert if visible
    Then I see alert contains text "<ExpectedAlertTitle>"
    And I see alert contains text "<ExpectedAlertBody>"

    Examples:
      | TeamOwner | TeamName   | Member1   | BrokenDeepLink       | ExpectedAlertTitle  | ExpectedAlertBody                 |
      | user1Name | Super club | user2Name | wire://usersx/xxxxxx | Invalid link.       | The link you opened is not valid. |

  @C749888 @deeplinks @regression @landscape
  Scenario Outline: I want to see a conversation when I was removed from it
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <Group> with <Contact1>,<Contact2>
    And User <Name> changes users <Contact1> to role Admin for conversation "<Group>"
    And All other versions of Wire are uninstalled
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends 1 default message to conversation <Group>
    And User <Contact1> removes user Me from group conversation <Group>
    And I open 1:1 conversation "<Contact1>" in conversation list
    # Last page: writing a text
    And I type the default message
    And I minimize Wire
    When I open deep link for conversation <Group> that user <Contact1> has sent me in safari
    And I accept notification permission alert if visible
    Then I see "<Contact1> removed you" system message in the conversation view
    And I see 1 default message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | Group |
      | user1Name | user2Name | user3Name | Gyoza |

  @C749911 @deeplinks @regression @landscape
  Scenario Outline: I want to see the group conversation when I am in it (conversation was deleted)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I swipe right on conversation <TeamGroup> in Conversations view
    And I tap Clear Content… conversation action button
    And I tap Clear conversation action button
    # Last page: Account settings
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I open group conversation details
    Then I see conversation name "<TeamGroup>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup |
      | user1Name | Super club | user2Name | user3Name | Nigiri    |

  @C749913 @deeplinks @regression @landscape
  Scenario Outline: I want to see the correct switch between conversations when I tap on two different conversation links continuously
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <TeamGroup1> with <Member1>,<Member2> in team <TeamName>
    And User <TeamOwner> has conversation <TeamGroup2> with <Member1> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    # Last page: Search UI
    When I open search screen
    And I minimize Wire
    When I open deep link for conversation <TeamGroup1> that user <TeamOwner> has sent me in safari
    And I accept notification permission alert if visible
    And I open group conversation details
    Then I see conversation name "<TeamGroup1>" on Group Details page
    And I minimize Wire
    When I open deep link for conversation <TeamGroup2> that user <TeamOwner> has sent me in safari
    And I open group conversation details
    Then I see conversation name "<TeamGroup2>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup1 | TeamGroup2 |
      | user1Name | Super club | user2Name | user3Name | Ramen      | Tempura    |

  @C749914 @deeplinks @unstable @landscape
  Scenario Outline: I want to see the correct conversation while I am in an audio call
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has 1:1 conversation with Me in team <TeamName>
    And <TeamOwner> starts instance using <CallBackend>
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And <TeamOwner> calls me
    And I accept alert if visible
    And I see Calling overlay
    And I tap Accept button on Calling overlay
    And I accept alert
    And <TeamOwner> verifies that call status to me is changed to active in <Timeout> seconds
    And I minimize Wire
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I accept notification permission alert if visible
    Then I see that Calling overlay is minimized
    And I open group conversation details
    And I see conversation name "<TeamGroup>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup | CallBackend | Timeout |
      | user1Name | Super club | user2Name | user3Name | Nigiri    | zcall_v3    | 20      |

  @C749915 @deeplinks @unstable @landscape
  Scenario Outline: I want to see the correct conversation while I am in a video call
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has 1:1 conversation with Me in team <TeamName>
    And <TeamOwner> starts instance using <CallBackend>
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And <TeamOwner> starts a video call to me
    And I see Calling overlay
    And I tap Accept button on Calling overlay
    # Camera permission
    And I accept alert
    # Mic permission
    And I accept alert
    And <TeamOwner> verifies that call status to me is changed to active in <Timeout> seconds
    And I minimize Wire
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    And I accept notification permission alert if visible
    Then I see that Calling overlay is minimized
    And I open group conversation details
    And I see conversation name "<TeamGroup>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup | CallBackend | Timeout |
      | user1Name | Super club | user2Name | user3Name | Nigiri    | zcall_v3    | 20      |

      #########################
      #      User profile     #
      #########################

  @C749916 @C749922 @deeplinks @unstable @landscape
  Scenario Outline: I want to see the correct user profile while I am in an audio call
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has 1:1 conversation with Me in team <TeamName>
    And <TeamOwner> starts instance using <CallBackend>
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And <TeamOwner> calls me
    And I accept alert if visible
    And I see Calling overlay
    And I tap Accept button on Calling overlay
    And I accept alert
    And <TeamOwner> verifies that call status to me is changed to active in <Timeout> seconds
    And I minimize Wire
    When I open deep link for profile of user <Member2> in safari
    And I accept notification permission alert if visible
    Then I see User profile popup page
    # Email is now visible for team members
    And I see user name <Member2> on User profile popup page
    And I see Information label on User profile popup page
    And I see key "Email" and value "<Member2Email>" at cell 1 on User profile popup page
    When I tap X button on User profile popup page
    Then I see conversations list
    And I see that Calling overlay is minimized

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | Member2Email | TeamGroup | CallBackend | Timeout |
      | user1Name | Super club | user2Name | user3Name | user3Email   | Nigiri    | zcall_v3    | 20      |

  @C749917 @deeplinks @unstable @landscape
  Scenario Outline: I want to see the correct user profile while I am in a video call
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has 1:1 conversation with Me in team <TeamName>
    And <TeamOwner> starts instance using <CallBackend>
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And <TeamOwner> starts a video call to me
    And I see Calling overlay
    And I tap Accept button on Calling overlay
    # Camera permission
    And I accept alert
    # Mic permission
    And I accept alert
    And <TeamOwner> verifies that call status to me is changed to active in <Timeout> seconds
    And I minimize Wire
    When I open deep link for profile of user <Member2> in safari
    And I accept notification permission alert if visible
    Then I see User profile popup page
    And I see user name <Member2> on User profile popup page
    When I tap X button on User profile popup page
    Then I see conversations list
    And I see that Calling overlay is minimized

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup | CallBackend | Timeout |
      | user1Name | Super club | user2Name | user3Name | Nigiri    | zcall_v3    | 20      |

  @C749918 @deeplinks @regression @landscape
  Scenario Outline: I should not see two profile popups open when i tap the same deep link twice
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And I minimize Wire
    When I open deep link for profile of user <Member2> in safari
    And I accept notification permission alert if visible
    And I minimize Wire
    And I open deep link for profile of user <Member2> in safari
    Then I see User profile popup page
    And I see user name <Member2> on User profile popup page
    When I tap X button on User profile popup page
    Then I do not see User profile popup page
    And I see conversations list

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   |
      | user1Name | Super club | user2Name | user3Name |

  @C749919 @deeplinks @regression @landscape
  Scenario Outline: I want to see my own profile
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And I minimize Wire
    When I open deep link for profile of user Myself in safari
    And I accept notification permission alert if visible
    Then I see User profile popup page
    And I see user name <Member1> on User profile popup page
    When I tap Open self profile button on User profile popup page
    Then I see name "<Member1>" on Self profile page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   |
      | user1Name | Super club | user2Name | user3Name |

  @C749920 @deeplinks @unstable @landscape
  Scenario Outline: I want to see an error message on a deep link with broken uuid [alert only shows locally]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And I minimize Wire
    When I open Safari with url "<BrokenDeepLink>"
    And I accept notification permission alert if visible
    Then I see alert contains text "<ExpectedAlertText>"

    Examples:
      | TeamOwner | TeamName   | Member1   | BrokenDeepLink     | ExpectedAlertText                                                     |
      | user1Name | Super club | user2Name | wire://user/xxxxxx | You may not have permission with this account or it no longer exists. |

  @C749890 @C749892 @C749923 @deeplinks @knownbug @landscape
  Scenario Outline: I want see the correct profiles as a team member - Bug [SQSERVICES-385]
    Given There are personal account users <Connected>,<NotConnected>
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member2> adds rich profile field "Title" with value "Chief Backup Officer"
    And User <Member2> adds rich profile field "Entity" with value "EMEA/PC BACKUP DEPARTMENT"
    And User <Member2> adds rich profile field "Email" with value "cdo@acme.com"
    And User <Member2> adds rich profile field "Phone" with value "09007800"
    And User <Member2> adds rich profile field "Personal Page" with value "https://acme.com/chief_design_office"
    And User <Member2> adds rich profile field "Favorite Quote" with value "Monads are just giant burritos 🌯"
    And User <Member1> is connected to <Connected>
    And User <Member1> is me
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I open Self profile
    And I open settings screen
    And I minimize Wire
    When I open deep link for profile of user <Member2> in safari
    And I accept notification permission alert if visible
    Then I see User profile popup page
    And I see user name <Member2> on User profile popup page
    And I see unique user name @<Member2UniqueUsername> on User profile popup page
    And I see profile picture on User profile popup page
    And I do not see GUEST label on User profile popup page
    And I see Information label on User profile popup page
    And I see key "Title" and value "Chief Backup Officer" at cell 2 on User profile popup page
    And I swipe up on User profile popup page
    And I see key "Entity" and value "EMEA/PC BACKUP DEPARTMENT" at cell 3 on User profile popup page
    And I see key "Personal Page" and value "https://acme.com/chief_design_office" at cell 6 on User profile popup page
    And I see key "Favorite Quote" and value "Monads are just giant burritos 🌯" at cell 7 on User profile popup page
    And I see Open Conversation button on User profile popup page
    And I do not see More Actions button on User profile popup page
    And I do not see Devices tab on User profile popup page
    When I minimize Wire
    And I open deep link for profile of user <Connected> in safari
    Then I see User profile popup page
    And I see user name <Connected> on User profile popup page
    And I see unique user name @<ConnectedUniqueUsername> on User profile popup page
    And I see profile picture on User profile popup page
    And I see GUEST label on User profile popup page
    And I do not see Devices tab on User profile popup page
    And I see Open Conversation button on User profile popup page
    And I tap More Actions button on User profile popup page
    And I see Block… conversation action button
    When I terminate Wire
    And I open deep link for profile of user <NotConnected> in safari
#      notifications alert
    And I accept alert if visible
    Then I see User profile popup page
    And I see user name <NotConnected> on User profile popup page
    And I see unique user name @<NotConnectedUniqueUsername> on User profile popup page
    And I see profile picture on User profile popup page
    And I see GUEST label on User profile popup page
    And I do not see Devices tab on User profile popup page
    And I see Connect button on User profile popup page
    And I do not see More Actions button on User profile popup page
    #I want to dismiss the user profile screen
    When I tap X button on User profile popup page
    Then I see conversations list
    And I do not see User profile popup page
      #settings modal should not display after closing popup
    And I do not see settings item Account

    Examples:
      | Member1   | TeamName | TeamOwner | Connected | NotConnected | Member2   | Member2UniqueUsername | ConnectedUniqueUsername | NotConnectedUniqueUsername |
      | user1Name | TeamDeep | user2Name | user3Name | user4Name    | user5Name | user5UniqueUserName   | user3UniqueUsername     | user4UniqueUserName        |

  @C749924 @deeplinks @regression @landscape
  Scenario Outline: I want see the correct profiles as a personal account
    Given There are personal account users <Name>,<NotConnected>
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Connected> to team <TeamName> with role Member
    And User <Connected> adds rich profile field "Title" with value "Chief Backup Officer"
    And User <Connected> adds rich profile field "Entity" with value "EMEA/PC BACKUP DEPARTMENT"
    And User <Connected> adds rich profile field "Email" with value "cdo@acme.com"
    And User <Connected> adds rich profile field "Phone" with value "09007800"
    And User <Connected> adds rich profile field "Personal Page" with value "https://acme.com/chief_design_office"
    And User <Connected> adds rich profile field "Favorite Quote" with value "Monads are just giant burritos 🌯"
    And User <Name> is connected to <Connected>
    And User <Name> is me
    And All other versions of Wire are uninstalled
    And I sign in user <Name> with fast login
    And I am signed in properly
    And I minimize Wire
    When I open deep link for profile of user <Connected> in safari
    Then I see User profile popup page
    And I see user name <Connected> on User profile popup page
    And I see unique user name @<ConnectedUniqueUsername> on User profile popup page
    And I see profile picture on User profile popup page
    And I do not see GUEST label on User profile popup page
    And I do not see Information label on User profile popup page
    And I do not see Devices tab on User profile popup page
    And I see Open Conversation button on User profile popup page
    And I see More Actions button on User profile popup page
    And I tap More Actions button on User profile popup page
    And I see Block… conversation action button
    And I dismiss popover on iPad
    When I tap X button on User profile popup page
    And I minimize Wire
    And I open deep link for profile of user <NotConnected> in safari
    Then I see User profile popup page
    And I see user name <NotConnected> on User profile popup page
    And I see unique user name @<NotConnectedUniqueUsername> on User profile popup page
    And I see profile picture on User profile popup page
    And I do not see GUEST label on User profile popup page
    And I do not see Devices tab on User profile popup page
    And I see Connect button on User profile popup page
    And I do not see More Actions button on User profile popup page
    When I tap X button on User profile popup page
    Then I see conversations list

    Examples:
      | Name      | TeamName | TeamOwner | Connected | NotConnected | ConnectedUniqueUsername | NotConnectedUniqueUsername |
      | user1Name | TeamDeep | user2Name | user3Name | user4Name    | user3UniqueUsername     | user4UniqueUsername        |

  ##########################
  #  Grouped Conversation  #
  ##########################

  @C814724 @deeplinks @regression @folders @landscape
  Scenario Outline: I want to see current list view when I click on a deeplink
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <TeamGroup> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    And I sign in user <Member1> with fast login
    And I opened the filters
    And I minimize Wire
    # Last page: Grouped Conversation list
    When I open deep link for conversation <TeamGroup> that user <TeamOwner> has sent me in safari
    # Opening the safari and then opening the app, it takes sometime and due to delay tests can fail so I put wait here
    And I wait for 3 seconds
    And I accept notification permission alert if visible
    Then I see conversation <TeamGroup> in Groups folder
    And I open group conversation details
    And I see conversation name "<TeamGroup>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   | Member2   | TeamGroup |
      | user1Name | Super club | user2Name | user3Name | Ramen     |
