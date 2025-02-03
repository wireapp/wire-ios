Feature: 2 Factor Authentication

  @C1137641 @C1137645 @C1137643 @C1137646 @regression @rc @2FA @useSpecialEmail
  Scenario Outline: I want to verify that verification code is required after login if 2F authentication is enabled for the team
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And Admin user <TeamOwner> unlocks 2F Authentication for team <TeamName>
    And Admin user <TeamOwner> enables 2 Factor Authentication for team <TeamName>
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And I tap Login button on Welcome page
#    C1137643 I want to see info that verification code has been sent
    When I sign in user <TeamOwner> with email
    Then I see email verification reminder
#    C1137645	I should not be able to proceed with invalid code
    When I enter "000000" as Verification Code on Verification Code page
    Then I do not see First Time overlay
#    C1137646 I want to see error message if invalid code was entered
    And I see alert contains text "Please enter a valid verification code"
#  C1137644	I want to receive new verification code email after clicking 'Resend code' button
    When I accept Please enter a valid code alert on Verification Code page
    And I tap Resend Code button on Verification Code page
    And I wait until 3 mails arrived for <Email>
    And I start verification email monitoring on mailbox <Email>
    And I enter verification code from Email
    Then I see First Time overlay
    When I accept First Time overlay
    Then I am signed in properly

    Examples:
      | TeamOwner | TeamName    | Member1   | Message     | Email      |
      | user1Name | AwesomeTeam | user2Name | Hi there    | user1Email |

  @C1137642 @C1137647 @C1137648 @regression @rc @2FA @useSpecialEmail
  Scenario Outline: I want to receive verification code via email after logging in
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And I start verification email monitoring on mailbox <Email>
    And Admin user <TeamOwner> unlocks 2F Authentication for team <TeamName>
    And Admin user <TeamOwner> enables 2 Factor Authentication for team <TeamName>
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And I tap Login button on Welcome page
    And I sign in user <TeamOwner> with email
    And I see email verification reminder
#    C1137647 I want to see verification code dialog/page disappearing after I enter valid code
    When I enter verification code from Email
    Then I see First Time overlay
#    C1137648	I want to verify that verification code is not required after login if 2F authentication has been disabled
    When I accept First Time overlay
    And I am signed in properly
    And Admin user <TeamOwner> disables 2 Factor Authentication for team <TeamName>
    And I open settings screen
    And I select settings item Account
    And I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I accept alert
    And I tap Login button on Welcome page
    And I sign in user <TeamOwner> with email
    And I accept First Time overlay
    Then I see conversations list
    When Admin user <TeamOwner> enables 2 Factor Authentication for team <TeamName>
    And I open settings screen
    And I select settings item Account
    And I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I accept alert
    And I tap Login button on Welcome page
    And I sign in user <TeamOwner> with email
    Then I see email verification reminder

    Examples:
      | TeamOwner | TeamName    | Member1   | Message     | Email      | Password      |
      | user1Name | AwesomeTeam | user2Name | Hi there    | user1Email | user1Password |
