Feature: Registration

  @C2768 @rc @regression @registration @landscape
  Scenario Outline: I want to register new user using email [LANDSCAPE]
    Given I tap Create An Account button on Welcome page
    And I see registration screen
    When I enter registration email "<Email>"
    And I accept terms of service
    And I enter activation code for the email address of <Name>
    And I see alert contains text "Do you want to receive news and product updates from Wire via email?"
    And I tap Accept button on the alert
    And I input name <Name> and commit it
    And I set the password to "<Password>"
    And I accept alert
    And I tap Keep This One button on Unique Username Takeover page
    And I accept alert if visible
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    Then I verify the value of settings item Name equals to "<Name>"

    Examples:
      | Email      | Password      | Name      |
      | user1Email | user1Password | user1Name |