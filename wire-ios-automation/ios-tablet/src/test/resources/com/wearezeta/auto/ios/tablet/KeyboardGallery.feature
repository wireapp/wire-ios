Feature: Keyboard Gallery

  @C194554 @regression @landscape
  Scenario Outline: I want to open gallery tapping on gallery icon [LANDSCAPE]
    Given I allow access to all photos
    And I allow camera access
    And There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    And I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    When I tap Camera Roll button on Keyboard Gallery overlay
    # Wait for gallery load
    And I wait for 10 seconds
    And I select a picture from Camera Roll
    And I tap Confirm button on Picture preview page
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C194555 @regression @landscape
  Scenario Outline: I can draw a sketch on picture from gallery [LANDSCAPE]
    Given I allow access to all photos
    And I allow camera access
    And There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    And I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I select the first item from Keyboard Gallery
    When I tap Sketch button on Picture Preview page
    And I draw a random sketch
    And I tap Send button on Sketch page
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |
