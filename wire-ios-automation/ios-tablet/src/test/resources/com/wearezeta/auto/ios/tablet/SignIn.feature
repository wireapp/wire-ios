Feature: Sign In

  @C3133 @rc @regression @login @landscape
  Scenario Outline: I want to sign in to ZClient [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I tap Login button on Welcome page
    And I enter login MyEmail on Login page
    And I enter password MyPassword on Login page
    And I tap Login button on Login page
    And I accept alert if visible
    And I accept First Time overlay
    And I accept alert
    Then I see conversations list

    Examples:
      | Name      |
      | user1Name |

  @C3132 @regression @login @landscape
  Scenario Outline: I want to see notification if SignIn credentials are wrong [LANDSCAPE]
    Given I tap Login button on Welcome page
    When I enter login <WrongMail> on Login page
    And I enter password <WrongPassword> on Login page
    Then I don't see the Login button
    When I enter login <BetterWrongMail> on Login page
    And I attempt to tap Login button
    Then I see alert contains text "<ExpectedText>"

    Examples:
      | WrongMail  | WrongPassword | BetterWrongMail   | ExpectedText                             |
      | wrongwrong | wrongwrong123 | wrong@wrong.wrong | Please verify your details and try again |

  @C2868 @regression @login @landscape
  Scenario Outline: I want to verify error message appears in case of registering already taken email [LANDSCAPE]
    Given I tap Create An Account button on Welcome page
    When I enter registration email "<Email>"
    And I accept terms of service
      # This might take some time on CI
    And I wait up until 5 seconds until alert is visible
    Then I see alert contains text "<ExpectedText>"

    Examples:
      | Email              | ExpectedText      |
      | nick+nqa1@wire.com | is already linked |

  @C845288 @C845287 @regression @rc @enterpriselogin @landscape
  Scenario: I want to see Enterprise Login button on the welcome page
    When I see Welcome page
    Then I see Enterprise Log In button on Welcome page
    # I should not see company sign in anymore
    When I tap Login button on Welcome page
    Then I should not see Company Login button on Login page
