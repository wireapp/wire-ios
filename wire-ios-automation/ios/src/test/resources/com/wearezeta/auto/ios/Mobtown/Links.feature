@mobtown
Feature: Links

  @TC-4880
  Scenario Outline: I should not see url of other ingress instance on self profile
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And I open mobtown-ernie backend deep link in safari
    And I accept Connect to server alert
    # TODO: Uncomment when https://wearezeta.atlassian.net/browse/SEC-414 fixed
    # And I see domain name of backend on Welcome page
    And I tap Login button on Welcome page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I am signed in properly
    And I open Self profile
    When I tap Manage Team button on Self profile page
    Then I see "teams.ernie.mobtown.wire.systems" web page opened

    Examples:
      | TeamOwner | TeamName | Email      | Password        |
      | user1Name | BestTeam | user1Email | user1Password   |

  @TC-4881
  Scenario Outline: I should not see url of other ingress instance on about screen
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And I open mobtown-ernie backend deep link in safari
    And I accept Connect to server alert
    # TODO: Uncomment when https://wearezeta.atlassian.net/browse/SEC-414 fixed
    # And I see domain name of backend on Welcome page
    And I tap Login button on Welcome page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I am signed in properly
    And I open settings screen
    And I select settings item About
    When I select settings item Wire Website
    Then I see "wire.com" in url bar of web page opened
    And I do not see "ernie" in url bar of web page opened
    And I do not see "systems" in url bar of web page opened
    And I close the web view
    When I select settings item Privacy Policy
    Then I see "wire.com" in url bar of web page opened
    And I do not see "ernie" in url bar of web page opened
    And I do not see "systems" in url bar of web page opened
    And I close the web view
    When I select settings item Terms of use
    Then I see "wire.com" in url bar of web page opened
    And I do not see "ernie" in url bar of web page opened
    And I do not see "systems" in url bar of web page opened

    Examples:
      | TeamOwner | TeamName | Email      | Password        |
      | user1Name | BestTeam | user1Email | user1Password   |

  @TC-4882
  Scenario Outline: I should not see url of other ingress instance on support screen
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And I open mobtown-ernie backend deep link in safari
    And I accept Connect to server alert
    # TODO: Uncomment when https://wearezeta.atlassian.net/browse/SEC-414 fixed
    # And I see domain name of backend on Welcome page
    And I tap Login button on Welcome page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I am signed in properly
    And I open Self profile
    And I open settings screen
    And I select settings item Support
    And I select settings item Wire Support Website
    Then I see "support.wire.com" in url bar of web page opened
    And I do not see "ernie" in url bar of web page opened
    And I do not see "systems" in url bar of web page opened
    And I close the web view
    And I select settings item Contact Support
    Then I see "support.wire.com" in url bar of web page opened
    And I do not see "ernie" in url bar of web page opened
    And I do not see "systems" in url bar of web page opened
    And I close the web view
    And I select settings item Report Misuse
    Then I see "support.wire.com" in url bar of web page opened
    And I do not see "ernie" in url bar of web page opened
    And I do not see "systems" in url bar of web page opened

    Examples:
      | TeamOwner | TeamName | Email      | Password        |
      | user1Name | BestTeam | user1Email | user1Password   |