@e2ei @mls
Feature: E2EI

  @TC-8192 @SF.Messages @TSFI.UserInterface @TSFI.ACME @S0.1 @S0.3 @S8 @col1 @Security
  Scenario Outline: I should not get a certificate if ACME server rejects identifier because user does not match
    Given There is a team owner "<Owner>" with team "MLS"
    And User <Owner> adds users <Member1>,<Member2> to team MLS with role Member
    And User <Owner> adds users <Member1>,<Member2> to keycloak for E2EI
    And User <Owner> configures MLS for team "MLS"
    And Admin user <Owner> enables E2EI with ACME server for team "MLS"
    And I open default backend via deep link in safari
    And I enroll the simulator for Touch ID
    And I tap Proceed button on backend redirection page
    And I tap Login button on Welcome page
    And I start verification email monitoring on mailbox <Member1Email>
    And I login as <Member1Email>
    And I tap Not Now on save password alert
    And I enter verification code from Email
    When I accept First Time overlay
    And I tap Get Certificate button on Enrollment overlay
    And I accept alert if visible
    Then I see keycloak web view
    And I enter email <Member2Email> on keycloak web view
    And I enter password <Member2Password> on keycloak web view
    And I click sign in button on keycloak web view
    Then I see certificate error message

    Examples:
      | Owner     | Member1   | Member1Email | Member2   | Member2Email | Member2Password |
      | user1Name | user2Name | user2Email   | user3Name | user3Email   | user3Password   |

  @TC-7979 @col1
  Scenario Outline: I should get a certificate if everything is valid
    Given There is a team owner "<Owner>" with team "E2EI"
    And User <Owner> adds users <Member1> to team E2EI with role Member
    And User <Owner> adds users <Member1> to keycloak for E2EI
    And User <Owner> configures MLS for team "E2EI"
    And Admin user <Owner> enables E2EI with ACME server for team "E2EI"
    And I open default backend via deep link in safari
    And I enroll the simulator for Touch ID
    And I tap Proceed button on backend redirection page
    And I enter login <Member1Email> on Login page
    And I enter password <Member1Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Member1Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I tap Get Certificate button on Enrollment overlay
    And I enter email <Member1Email> on keycloak web view
    And I enter password <Member1Password> on keycloak web view
    And I click sign in button on keycloak web view
    And I click Ok on the Enrollment Success screen
    And I perform successful Touch ID
    And I am signed in properly
    Then I see that I am certified on Conversation List Page
    When I open Self profile
    And I open settings screen
    And I select settings item Devices
    And I open details page of device number 1 on Settings page
    And I open my certificate details
    Then I see certificate details info
    Examples:
      | Owner     | Member1   | Member1Email | Member1Password |
      | user1Name | user2Name | user2Email   | user2Password   |

  @TC-8193 @SF.Messages @TSFI.UserInterface @TSFI.ACME @S0.1 @S0.3 @S8 @col1 @Security
  Scenario Outline: I should not get a certificate if TLS certificate of ACME is invalid
    Given There is a team owner "<Owner>" with team "MLS"
    And User <Owner> adds users <Member1> to team MLS with role Member
    And User <Owner> adds users <Member1> to keycloak for E2EI
    And User <Owner> configures MLS for team "MLS"
    And Admin user <Owner> enables E2EI with insecure ACME server for team "MLS"
    And I open default backend via deep link in safari
    And I enroll the simulator for Touch ID
    And I tap Proceed button on backend redirection page
    And I enter login <Member1Email> on Login page
    And I enter password <Member1Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Member1Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I tap Get Certificate button on Enrollment overlay
    Then I see certificate error message

    Examples:
      | Owner     | Member1   | Member1Email | Member1Password |
      | user1Name | user2Name | user2Email   | user2Password   |

  @col1
  Scenario Outline: Admin revoking a certificate and then user can remove their revoked device
    Given There is a team owner "<Owner1>" who sets up team "E2EI" for E2EI on column-1 backend
    When I login to the default email verified backend as <Owner1>
    And I tap Get Certificate button on Enrollment overlay
    And I accept alert if visible
    Then I see keycloak web view
    And I login to keycloak as "<Owner1>"
    And I click Ok on the Enrollment Success screen
    And I perform successful Touch ID
    And I press enter on the Encryption At Rest overlay input
    When I open Self profile
    And I open settings screen
    And I select settings item Devices
    And I open details page of device number 1 on Settings page
    And I open my certificate details
    And I copy my certificate details
    And Admin of column-1 backend revokes remembered certificate on ACME server
    When I reset Wire
    When I login to the default email verified backend as <Owner1>
    And I accept alert if visible
    And I tap Get Certificate button on Enrollment overlay
    And I accept alert if visible
    Then I see keycloak web view
    And I login to keycloak as "<Owner1>"
    And I click Ok on the Enrollment Success screen
    And I accept alert if visible
    And I perform successful Touch ID
    When I open Self profile
    And I open settings screen
    And I select settings item Devices
    And I open details page of device number 2 on Settings page
    Then I should see a revoked certificate in Device Details
    When I tap Remove Device button on Device Details page
    And I confirm with my <Owner1Password> the deletion of the device on Settings page
    Then I see 1 device is shown on Settings page
    Examples:
      | Owner1     | Owner1Password |
      | user1Name  | user1Password  |
