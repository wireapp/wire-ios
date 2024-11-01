Feature: Copy/Delete Message

  @C119753 @regression @landscape
  Scenario Outline: I want to verify copy/delete menu disappears on the rotation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I see conversations list
    And User <Contact> sends 1 default message to conversation Myself
    When I open conversation "<Contact>" in conversation list
    And I long tap default message in conversation view
    Then I see Copy on edit menu
    When I rotate UI to portrait
    Then I do not see Copy on edit menu

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C145958 @rc @regression @landscape
  Scenario Outline: I want to delete Message. Verify deleting a picture [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I see conversations list
    And User <Contact> sends 1 image file <Picture> to conversation Myself
    And User <Contact> sends <MessagesCount> default messages to conversation Myself
    When I open conversation "<Contact>" in conversation list
    Then I see 1 photo in the conversation view
    And I see <MessagesCount> default messages in the conversation view
    When I long tap on image in conversation view
    And I tap on Delete on edit menu
    And I select Delete for Me item from Delete menu
    Then I see 0 photos in the conversation view
    And I see <MessagesCount> default messages in the conversation view

    Examples:
      | Name      | Contact   | Picture     | MessagesCount |
      | user1Name | user2Name | testing.jpg | 2             |

  @C145957 @regression @rc @landscape
  Scenario Outline: I want to verify deleting sent text message [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I type the default message and send it
    When I long tap default message in conversation view
    And I tap on Delete on edit menu
    And I select Delete for Me item from Delete menu
    Then I see 0 default messages in the conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |