Feature: Voice Filters

  @C169215 @rc @regression @landscape
  Scenario Outline: I want to record an audio message and apply voice filter to it [LANDSCAPE] - [Fails on Jenkins]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    When I open conversation "<Contact>" in conversation list
    And I tap Audio Message button from input tools
    And I accept alert if visible
    And I tap Start Recording button on Voice Filters overlay
    And I wait for 5 seconds
    And I tap Stop Recording button on Voice Filters overlay
    And I tap <ButtonsCount> random effect buttons on Voice Filters overlay
    And I tap Confirm button on Voice Filters overlay
    Then I see audio message container in the conversation view
    And I do not see Confirm button on Voice Filters overlay

    Examples:
      | Name      | Contact   | ButtonsCount |
      | user1Name | user2Name | 4            |

  @C169216 @rc @regression @landscape
  Scenario Outline: I want to verify sending original audio without any filters [LANDSCAPE] - [Fails on Jenkins]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    When I open conversation "<Contact>" in conversation list
    And I tap Audio Message button from input tools
    And I accept alert if visible
    And I tap Start Recording button on Voice Filters overlay
    And I wait for 5 seconds
    And I tap Stop Recording button on Voice Filters overlay
    And I tap Confirm button on Voice Filters overlay
    Then I see audio message container in the conversation view
    And I do not see Confirm button on Voice Filters overlay

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |
