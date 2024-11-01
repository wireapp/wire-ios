Feature: Log Out

  @TC-6258 @logout @col1 @SF.Provisioning @TSFI.UserInterface @TSFI.RESTfulAPI @S0.1 @S2 @BundSecurity
  Scenario Outline: I want to verify the appropriate device is logged out if you remove it from settings
    Given There is a team owner "<Name>" with team "<Name>" on column-1 backend
    And User <Name> is me
    When I login to the default email verified backend as <Name>
    Then I am signed in properly
    And I see conversations list
    When User Myself removes all their registered OTR clients
    Then I see alert contains text "Your session expired"
    When I accept alert
    Then I see Login page

    Examples:
      | Name      |
      | user1Name |

  @TC-6091 @logout @col1 @SF.Provisioning @TSFI.UserInterface @TSFI.RESTfulAPI @S0.1 @S2 @BundSecurity
  Scenario Outline: I want to verify immediately being logged out after being removed from team
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    When I login to the default email verified backend as <Member1>
    Then I am signed in properly
    When User <TeamOwner> removes user <Member1> from team <TeamName>
    Then I see alert title contains text "<SessionTimeoutText>"

    Examples:
      | TeamOwner | Member1    | TeamName | SessionTimeoutText   |
      | user1Name | user2Name  | kickme   | Your session expired |
