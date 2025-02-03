Feature: Log Out

  @TC-6086 @regression @logout
  Scenario Outline: I want to logout
    Given There is a team owner "<Name>" with team "MyTeam"
    And I tap Login button on Welcome page
    And I sign in user <Name> with email
    And I accept First Time overlay
    And I am signed in properly
    And I open settings screen
    And I select settings item Account
    When I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I accept alert
    Then I see Welcome page

    Examples:
      | Name      | Password      |
      | user1Name | user1Password |

  @TC-6087 @regression @regression @logout
  Scenario Outline: I want to verify logging out from a team account when personal account is still logged in
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And There are personal account users <PersonalAccount>,<PersonalContact>
    And User <PersonalAccount> is me
    And User Myself is connected to <PersonalContact>
    And I tap Login button on Welcome page
    And I sign in user <PersonalAccount> with email
    And I accept First Time overlay
    And I see conversation <PersonalContact> in conversations list
    And I open Self profile
    And User <Member1> is me
    And I tap Add Account button on Self profile page
    And I tap Login button on Welcome page
    And I sign in user <Member1> with email
    And I accept First Time overlay
    And I am signed in properly
    And I see conversation <ConversationName> in conversations list
    And I open settings screen
    And I select settings item Account
    When I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I accept alert
    Then I see conversation <PersonalContact> in conversations list

    Examples:
      | TeamOwner | TeamName  | Member1   | Member2   | ConversationName | PersonalAccount | PersonalContact | Password      |
      | user1Name | SuperTeam | user2Name | user3Name | Team Convo       | user4Name       | user5Name       | user2Password |

  @TC-6090 @regression @logout
  Scenario Outline: I want to verify history is erased after logging out from the account
    Given There are personal account users <Name>, <Contact>
    And User <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I tap Login button on Welcome page
    And I sign in user <Name> with email
    And I accept First Time overlay
    And I am signed in properly
    And User <Contact> sends 1 default message to conversation Myself
    And User <Contact> sends 1 image file <Picture> to conversation Myself
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    And I see 1 photo in the conversation view
    And I see 1 default message in the conversation view
    And I navigate back to conversations list
    And I open settings screen
    And I select settings item Account
    And I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I accept alert
    And I see Welcome page
    And I tap Login button on Welcome page
    And I enter login MyEmail on Login page
    And I enter password MyPassword on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I am signed in properly
    When I open conversation "<Contact>" in conversation list
    Then I see 0 default messages in the conversation view
    And I see 0 photos in the conversation view

    Examples:
      | Name      | Contact   | Picture     | Password      |
      | user1Name | user2Name | testing.jpg | user1Password |

  @TC-6258 @regression @logout @TSFI.UserInterface @TSFI.RESTfulAPI @S0.1 @S2
  Scenario Outline: I want to verify the appropriate device is logged out if you remove it from settings
    Given There is 1 user where <Name> is me
    And I tap Login button on Welcome page
    And I sign in user <Name> with email
    And I accept First Time overlay
    And I am signed in properly
    And I see conversations list
    When User Myself removes all their registered OTR clients
    Then I see alert contains text "Your session expired"
    When I accept alert
    Then I see Welcome page

    Examples:
      | Name      |
      | user1Name |

  @TC-6091 @regression @logout @TSFI.UserInterface @TSFI.RESTfulAPI @S0.1 @S2
  Scenario Outline: I want to verify immediately being logged out after being removed from team
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I am signed in properly
    When User <TeamOwner> removes user <Member1> from team <TeamName>
    Then I see alert title contains text "<SessionTimeoutText>"

    Examples:
      | TeamOwner | Member1    | TeamName | SessionTimeoutText   |
      | user1Name | user2Name  | kickme   | Your session expired |
