Feature: Rich Profile

  @C747584 @scim @rc @unstable
  Scenario Outline: I should not be able to change name, unique username, accent color, profile picture of user managed by SCIM
    Given There is a team owner "<TeamOwner>" with SSO team "<TeamName>" configured for okta
    And User <TeamOwner> adds user <OktaMember1> to okta and SCIM
    And User <OktaMember1> is me
    And I tap Enterprise Login button on Welcome page
    And I accept alert
    And I see Enterprise Login popup
    And I type the default SSO code on Enterprise Login popup
    And I tap Login button on Enterprise Login popup
    And I see okta web view
    And I enter user name MyEmail on okta web view
    And I enter password MyPassword on okta web view
    And I click sign in button on okta web view
    And I wait for 3 seconds
    And I accept First Time overlay
    And I wait for 3 seconds
    And I open Self profile
    And I open settings screen
    When I select settings item Account
    And I verify the value of settings item Name equals to "<OktaMember1>"
    And I see "<UniqueUsername>" unique username is displayed on Settings Page
    Then I can not change display name on Settings page
    And I can not change unique username on Settings page
    And I do not see Appearance section on Settings page
    And I do not see settings item Phone
    And I do not see settings item Email

    Examples:
      | TeamOwner | TeamName | OktaMember1 | UniqueUsername      |
      | user1Name | Pose     | user2Name   | user2UniqueUsername |

  @C747585 @scim @richprofile @rc @unstable
  Scenario Outline: I want to see the rich profile of other team member from 1:1
    Given There is a team owner "<TeamOwner>" with SSO team "<TeamName>" configured for okta
    And User <TeamOwner> adds user <OktaMember1>,<OktaMember2> to okta and SCIM
    And User <OktaMember2> adds rich profile field "Title" with value "Chief Backup Officer"
    And User <OktaMember2> adds rich profile field "Entity" with value "EMEA/PC BACKUP DEPARTMENT"
    And User <OktaMember1> is me
    And I tap Enterprise Login button on Welcome page
    And I accept alert if visible
    And I see Enterprise Login popup
    And I type the default SSO code on Enterprise Login popup
    And I tap Login button on Enterprise Login popup
    And I see okta web view
    And I enter user name MyEmail on okta web view
    And I enter password MyPassword on okta web view
    And I click sign in button on okta web view
    And I wait for 5 seconds
    And I accept First Time overlay
    And I accept alert if visible
    And I wait for 3 seconds
    When I open search screen
    And I tap on conversation <OktaMember2> in search result
    When I open conversation details
    Then I see Information label on Single user profile page
    And I see key "Title" and value "Chief Backup Officer" at cell 1 on Single user profile page
    And I see key "Entity" and value "EMEA/PC BACKUP DEPARTMENT" at cell 2 on Single user profile page

    Examples:
      | TeamOwner | TeamName | OktaMember1 | OktaMember2 |
      | user1Name | Pose     | user2Name   | user3Name   |

  @C747586 @scim @richprofile @regression
  Scenario Outline: I want to see a rich profile with a lot of entries (scrolling needed)
    Given There is a team owner "<TeamOwner>" with SSO team "<TeamName>" configured for okta
    And User <TeamOwner> adds user <OktaMember1>,<OktaMember2> to okta and SCIM
    And User <OktaMember2> adds rich profile field "Title" with value "Chief Backup Officer"
    And User <OktaMember2> adds rich profile field "Entity" with value "EMEA/PC BACKUP DEPARTMENT"
    And User <OktaMember2> adds rich profile field "Email" with value "cdo@acme.com"
    And User <OktaMember2> adds rich profile field "Phone" with value "09007800"
    And User <OktaMember2> adds rich profile field "Personal Page" with value "https://acme.com/chief_design_office"
    And User <OktaMember2> adds rich profile field "Favorite Quote" with value "Monads are just giant burritos 🌯"
    And User <OktaMember2> adds rich profile field "Title2" with value "Chief Backup Officer"
    And User <OktaMember2> adds rich profile field "Entity2" with value "EMEA/PC BACKUP DEPARTMENT"
    And User <OktaMember2> adds rich profile field "Email2" with value "cdo@acme.com"
    And User <OktaMember2> adds rich profile field "Phone2" with value "09007800"
    And User <OktaMember2> adds rich profile field "Personal Page2" with value "https://acme.com/chief_design_office"
    And User <OktaMember2> adds rich profile field "Favorite Quote2" with value "Monads are just giant burritos 🌯"
    And User <OktaMember1> is me
    And I tap Enterprise Login button on Welcome page
    And I see Enterprise Login popup
    And I type the default SSO code on Enterprise Login popup
    And I tap Login button on Enterprise Login popup
    And I see okta web view
    And I enter user name MyEmail on okta web view
    And I enter password MyPassword on okta web view
    And I tap Done keyboard button
    And I accept First Time overlay
    And I accept alert if visible
    When I open search screen
    And I tap on conversation <OktaMember2> in search result
    When I open conversation details
    Then I see Information label on Single user profile page
    And I see key "Title" and value "Chief Backup Officer" at cell 1 on Single user profile page
    And I see key "Entity" and value "EMEA/PC BACKUP DEPARTMENT" at cell 2 on Single user profile page
    When I swipe up on Single user profile page
    Then I see key "Personal Page2" and value "https://acme.com/chief_design_office" at cell 11 on Single user profile page
    And I see key "Favorite Quote2" and value "Monads are just giant burritos 🌯" at cell 12 on Single user profile page
    And I swipe up on Single user profile page
    And I see Read Receipt Footer on Single user profile page

    Examples:
      | TeamOwner | TeamName | OktaMember1 | OktaMember2 |
      | user1Name | Pose     | user2Name   | user3Name   |