Feature: Personal Account Lifecycle

  @flows @TC-8587
  Scenario Outline: Personal account lifecycle
    Given There are personal account users <PersonalAccount>
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
    Then User <Email> sent connection request to <PersonalAccount>
    Then User <PersonalAccount> accepts connection request from <Email>

    Examples:
      | Name      | Password      | Email      | UniqueUsername      | PersonalAccount |
      | user1Name | user1Password | user1Email | user1UniqueUsername | User2Name       |
