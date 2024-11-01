@mobtown
Feature: Text Messages

  @TC-4877
  Scenario Outline: I want to send and receive text messages on both ingress instances
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User adds the following devices: {"<TeamOwner>": [{"name": "device1"}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I open <Backend> backend deep link in safari
    And I accept Connect to server alert
    # TODO: Uncomment when https://wearezeta.atlassian.net/browse/SEC-414 fixed
    # And I see domain name of backend on Welcome page
    And I tap Login button on Welcome page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I am signed in properly
    And I open conversation "<TeamOwner>" in conversation list
    When User <TeamOwner> sends 1 "Hello from Owner" message to conversation Myself
    Then I see last message in the conversation view is expected message Hello from Owner
    When I type the "Hello, Owner!" message and send it
    Then I see last message in the conversation view is expected message Hello, Owner!

    Examples:
      | Backend       | Member1   | TeamOwner | TeamName | Email      | Password        |
      | mobtown-test  | user1Name | user2Name | BestTeam | user1Email | user1Password   |
      | mobtown-ernie | user1Name | user2Name | BestTeam | user1Email | user1Password   |