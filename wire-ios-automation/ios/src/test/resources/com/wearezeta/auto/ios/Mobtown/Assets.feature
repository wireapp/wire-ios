@mobtown
Feature: Assets

  @TC-4878
  Scenario Outline: I want to send and receive images on both ingress instances
    Given I allow access to all photos
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
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
    When User <TeamOwner> sends image with QR code containing "Image from Owner" to conversation <Member1>
    Then I see an image with QR code "Image from Owner" in the conversation view
    And I push image with QR code containing "Image" to camera roll
    When I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I tap Camera Roll button on Keyboard Gallery overlay
    And I select first picture from Camera Roll
    And I tap Confirm button on Picture preview page
    Then I see an image with QR code "Image" in the conversation view

    Examples:
      | Backend       | Member1   | TeamOwner | TeamName | Email      | Password        |
      | mobtown-test  | user1Name | user2Name | BestTeam | user1Email | user1Password   |
      | mobtown-ernie | user1Name | user2Name | BestTeam | user1Email | user1Password   |

  @TC-4879
  Scenario Outline: I want to receive files on both ingress instances
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
    When User <TeamOwner> sends 1KB sized file with MIME type text/plain and name example.txt to conversation <Member1>
    Then I wait up to 15 seconds until the file example.txt with size 1 KB is ready for download from conversation view
    When I tap ellipsis button from input tools
    And I tap File Transfer button from input tools
    And I tap file transfer option to send CountryCodes.plist file
    Then I wait up to 15 seconds until the file CountryCodes.plist with size 11 KB is ready for download from conversation view

    Examples:
      | Backend       | Member1   | TeamOwner | TeamName | Email      | Password        |
      | mobtown-test  | user1Name | user2Name | BestTeam | user1Email | user1Password   |
      | mobtown-ernie | user1Name | user2Name | BestTeam | user1Email | user1Password   |