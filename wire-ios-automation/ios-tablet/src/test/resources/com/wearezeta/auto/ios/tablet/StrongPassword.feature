Feature: Strong Password

  @C751508 @rc @regression @strongpassword @landscape
  Scenario Outline: I want to see the password policy instruction turns red when I submit an invalid password as personal acc
    Given I tap Create An Account button on Welcome page
    And I see registration screen
    And I enter registration email "<Email>"
    And I accept terms of service
    And I enter activation code for the email address of <Name>
    And I see alert contains text "Do you want to receive news and product updates from Wire via email?"
    And I tap Accept button on the alert
    When I input name <Name> and commit it
    Then I see password rules
    When I enter registration password "<Password1>"
    Then I see password failure message
    And I clear password input
    When I enter registration password "<Password2>"
    Then I see password failure message
    And I clear password input
    When I enter registration password "<Password3>"
    Then I see password failure message
    And I clear password input
    When I enter registration password "<Password4>"
    Then I see password failure message

    Examples:
      | Email      | Password1      | Name      | Password2    | Password3     | Password4     |
      | user1Email | doom1password! | user1Name | doomPassword!| doom1Password | DOOM1PASSWORD!|