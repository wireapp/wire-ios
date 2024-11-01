Feature: Collection

  @C395995 @rc @regression @landscape
  Scenario Outline: I want to verify you can see collections properly after changing display orientation
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 2 image files <Picture> to conversation Myself
    And I open conversation "<Contact>" in conversation list
    # Wait for load
    And I wait for 3 seconds
    And I tap Collection button in conversation view
    When I tap the item number 1 in collection category PICTURES
    Then I see full-screen image preview in collection view
    And I rotate UI to portrait
    When I tap X button in collection view
    Then I see 2 photos in the conversation view

    Examples:
      | Name      | Contact   | Picture     |
      | user1Name | user2Name | testing.jpg |
