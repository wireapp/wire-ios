Feature: Giphy

  @C2696 @regression @landscape
  Scenario Outline: I want to verify preview is opened after tapping on GIF button [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I type the "<GiphyTag>" message
    And I tap GIF button from input tools
    And I see Giphy grid preview
    And I select the first item from Giphy grid
    Then I see Giphy preview page

    Examples:
      | Name      | Contact   | GiphyTag |
      | user1Name | user2Name | Wow      |

  @C2695 @regression @landscape
  Scenario Outline: I want to verify I can send gif from preview [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I type the "<GiphyTag>" message
    And I tap GIF button from input tools
    And I select the first item from Giphy grid
    And I tap Send button on Giphy preview page
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact   | GiphyTag |
      | user1Name | user2Name | Happy    |