Feature: Single Sign On

  @C699056 @enterpriselogin @sso @regression @landscape
  Scenario Outline: I shall not be able to login when I paste a wrong/not valid SSO code format into the field [LANDSCAPE]
    Given I load clipboard content from string "<SSO Code>"
    And I restart Wire
    And I see Welcome page
    And I do not see Enterprise Login popup
    And I tap Enterprise Login button on Welcome page
    When I type "<SSO Code>" into EmailSSO code field
    And I tap Login button on Enterprise Login popup
    Then I see Enterprise Login popup contains text "<ExpectedAlertText>"

    Examples:
      | SSO Code                                    | ExpectedAlertText                             |
      | signal-498b2e76-147a-431c-83ac-ac65d36d1dcf | Please enter a valid email or SSO access code |

  @C699058 @enterpriselogin @sso @regression
  Scenario Outline: I should not be able to see prefilled popups on Welcome page/registration screen/create team (no pre-login account)
    Given I load clipboard content from string "<SSO Code>"
    When I restart Wire
    And I tap Enterprise Login button on Welcome page
    #Welcome page
    Then I see EmailSSO code field prefilled with text "<SSO Code>"
    And I tap Cancel button on Enterprise Login popup
    And I do not see Enterprise Login popup
    #Registration
    When I tap Create An Account button on Welcome page
    Then I do not see Enterprise Login popup
    When I tap Back button on Registration page
    Then I do not see Enterprise Login popup

    Examples:
      | SSO Code                                  |
      | wire-498b2e76-147a-431c-83ac-ac65d36d1dcf |

  @C699057 @enterpriselogin @sso @regression @landscape
  Scenario Outline: I want to be able to manually type the SSO code into the field [LANDSCAPE]
    Given I tap Enterprise Login button on Welcome page
    When I see Enterprise Login popup contains text "<ExpectedAlertText>"
    And I type "<SSO Code>" into EmailSSO code field
    Then I tap Login button on Enterprise Login popup

    Examples:
      | SSO Code                                  | ExpectedAlertText                   |
      | wire-498b2e76-147a-431c-83ac-ac65d36d1dcf | Please enter your email or SSO code |

  @C700183 @enterpriselogin @sso @regression
  Scenario Outline: I want to register a SSO client with already signed in personal account
    Given There is 1 user where <Name> is me
    And I tap Login button on Welcome page
    And I Sign in on tablet using my email
    And I accept First Time overlay
    And I am signed in properly
    And I accept Help us make Wire better popup
    And There is a team owner "<TeamOwner>" with SSO team "<TeamName>" configured for okta
    And User <TeamOwner> adds user <OktaMember1> to okta
    And I load clipboard content with sso code from okta
    And I open Self profile
    When I tap Add Account button on Self profile page
    And I tap Enterprise Login button on Welcome page
    And I tap Login button on Enterprise Login popup
    Then I see okta web view
    When I enter user name <OktaMember1Email> on okta web view
    And I enter password <OktaMember1Password> on okta web view
    And I tap Done keyboard button
    And I accept First Time overlay
    And I tap Keep This One button on Unique Username Takeover page
    Then I see conversations list

    Examples:
      | Name      | TeamOwner | TeamName  | OktaMember1 | OktaMember1Password | OktaMember1Email |
      | user1Name | user2Name | SuperTeam | user3Name   | user3Password       | user3Email       |
