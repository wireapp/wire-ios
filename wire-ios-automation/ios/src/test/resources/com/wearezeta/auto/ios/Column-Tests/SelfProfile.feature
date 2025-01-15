Feature: Self Profile

  @TC-5008 @TC-5009 @TC-5010 @col1
  Scenario Outline: I should not be able to change my domain name when I change my username
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open Self profile
    And I open settings screen
    And I select settings item Account
    When I select settings item Username
    Then I see domain name of user <TeamOwner> on Username UI
    And I see domain name is not editable of user <TeamOwner> on Username UI
    # I should not be able to add special characters in my display user name - TC-5009
    When I clear Username input field on Settings page
    And I enter "" name on Unique Username page
    Then I see Save button state is Disabled on Unique Username page
    When I enter "!@I #$%^&*,(,),,+=;:?\\/,," name on Unique Username page
    Then I see Save button state is Disabled on Unique Username page
    # I want to see my domain and team name in my Profile - TC-5010
    When I tap Save button on Unique Username page
    And I tap on the account back button
    Then I see domain name of user <TeamOwner> on settings item Domain
    And I see domain name on settings item is not editable
    And I see unique username and domain of user <TeamOwner> is displayed on Settings Page
    And I see team name as <TeamName> on settings item Team
    And I see team name on settings item is not editable
    And I verify the value of settings item Email equals to "<Email>"

    Examples:
      | TeamOwner | TeamName     | Email      |
      | user1Name | Stinky Pinky | user1Email |

  @TC-5011 @TC-5012 @col1
  Scenario Outline: I want to change my Email from settings
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Email
    And I start activation email monitoring on mailbox <NewEmail>
    When I change email address to <NewEmail> on Settings page
    And I tap Save navigation button on Settings page
    And I wait for 3 seconds
    And I verify email address <NewEmail> for Myself
    And I wait until the UI detects successful email activation on Settings page
    Then I verify the value of settings item Email equals to "<NewEmail>"
    And I verify user's Myself email on the backend is equal to <NewEmail>
    # TC-5012 - I want to change name from settings
    When I tap Go back to Settings navigation button on Settings page
    And I select settings item Account
    And I select settings item Name
    And I set "<NewUsername>" value to Name input field on Settings page
    And I tap Return button on the keyboard
    And I tap X navigation button on Settings page
    And I see conversations list
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    Then I verify the value of settings item Name equals to "<NewUsername>"

    Examples:
      | TeamOwner | TeamName     | NewEmail   | NewUsername |
      | user1Name | Stinky Pinky | user2Email | NewName     |

  @TC-5013 @col1
  Scenario Outline: I want to change my profile picture from settings
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open Self profile
    And I wait for 5 seconds
    When I tap my picture preview on Self profile page
    And I see Take Photo button on Camera page

    Examples:
      | TeamOwner | TeamName     |
      | user1Name | Stinky Pinky |