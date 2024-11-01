Feature: 2FA

  @TC-4883 @col1 @SF.Channel @TSFI.UserInterface @S0.1 @S2 @BundSecurity
  Scenario Outline: I should not be able to login with invalid 2FA verification code if 2FA is enabled on backend
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"},{}]}
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    And I enroll the simulator for Touch ID
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    When I type 2FA verification code 123456 into fields
    Then I do not see First Time overlay
    And I see alert contains text "Please enter a valid code"
    When I accept alert
    And I type 2FA verification code 654321 into fields
    Then I do not see First Time overlay
    And I see alert contains text "Please enter a valid code"
    When I accept alert
    And I enter "000000" as Verification Code on Verification Code page
    Then I do not see First Time overlay
    And I see alert contains text "Please enter a valid code"

    Examples:
      | TeamOwner | TeamName    | Email      | Password        |
      | user1Name | AwesomeTeam |  user1Email | user1Password   |

  @TC-4886 @col1
  Scenario Outline: I want to use back button on verification code page
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"},{}]}
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    And I enroll the simulator for Touch ID
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    When I tap Back button on Verification Code page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I enter verification code from Email
    And I tap Not Now on save password alert
    Then I see First Time overlay

    Examples:
      | TeamOwner | TeamName    | Email      | Password        |
      | user1Name | AwesomeTeam | user1Email | user1Password   |

  @TC-4885 @col1 @SF.Channel @TSFI.UserInterface @S0.1 @S2 @BundSecurity
  Scenario Outline: I want to verify that verification code is required on login only if 2FA is enabled on backend
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And All other versions of Wire are uninstalled
    And I enroll the simulator for Touch ID
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly

    Examples:
      | TeamOwner | TeamName    |
      | user1Name | AwesomeTeam |

  @TC-4884 @col1
  Scenario Outline: I want to receive new verification code email after clicking 'Resend code' button
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"},{}]}
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I tap Resend Code button on Verification Code page
    And I wait until 2 mails arrived for <Email>
    And I start verification email monitoring on mailbox <Email>
    And I enter verification code from Email
    Then I see First Time overlay
    When I accept First Time overlay
    Then I am signed in properly

    Examples:
      | TeamOwner | TeamName    | Email      | Password        |
      | user1Name | AwesomeTeam | user1Email | user1Password   |