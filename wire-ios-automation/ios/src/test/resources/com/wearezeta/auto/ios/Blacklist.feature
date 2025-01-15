Feature: Blacklist

  @TC-5424 @rc @blacklist
  Scenario Outline: I want to exclude params works in blacklist
    Given There is 1 user where user1Name is me
    When I open a backend which has my build blacklisted via deep link in safari
    And I tap Proceed button on backend redirection page
    And I tap Login button on Welcome page
    And I login as user1Email
    Then I see alert contains text "<AlertText>"

    Examples:
      | AlertText        |
      | Update necessary |

  @TC-5425 @rc @blacklist
  Scenario Outline: I want to verify min params works in blacklist
    Given There is 1 user where user1Name is me
    When I open a backend which has a higher minimum version via deep link in safari
    And I tap Proceed button on backend redirection page
    And I tap Login button on Welcome page
    And I login as user1Email
    Then I see alert contains text "<AlertText>"

    Examples:
      | AlertText        |
      | Update necessary |
