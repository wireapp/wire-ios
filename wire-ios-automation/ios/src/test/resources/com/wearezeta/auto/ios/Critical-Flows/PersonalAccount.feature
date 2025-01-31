Feature: Personal Account Lifecycle

  @flows @TC-8587
  Scenario Outline: Personal account lifecycle
    When I tap Create An Account button on Welcome page
    And I see registration screen
    And I enter registration email "<Email>"
    And I accept terms of service
    And I enter activation code for the email address of <Name>
    And I input name <Name> and commit it
    And I set the password to "<Password>"
    And I set the username to <UniqueUsername>
    And I accept alert if visible
    Then I am signed in properly

    Examples:
      | Name      | Password      | Email      | UniqueUsername      |
      | user1Name | user1Password | user1Email | user1UniqueUsername |
