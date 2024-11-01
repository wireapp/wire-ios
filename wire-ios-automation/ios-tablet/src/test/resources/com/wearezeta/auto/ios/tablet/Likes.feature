Feature: Likes

  @C246217 @rc @regression @landscape
  Scenario Outline: I want to verify liking/unliking a message by tapping on like icon
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 default message to conversation Myself
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    When I tap default message in conversation view
    And I remember the state of Like icon in the conversation
    And I tap Like icon in the conversation
    Then I see the state of Like icon is changed in the conversation
    When I tap Unlike icon in the conversation
    Then I see the state of Like icon is not changed in the conversation

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C246224 @C246225 @regression @landscape
  Scenario Outline: I want to verify liking image and link [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 image file <Picture> to conversation Myself
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    When I long tap on image in conversation view
    And I tap on Like on edit menu
    And I remember the state of Like icon in the conversation
    And I tap Like icon in the conversation
    Then I see the state of Like icon is changed in the conversation
    When User <Contact> sends 1 "<Link>" message to conversation Myself
    # Wait for the preview to be generated
    And I wait for 5 seconds
    And I long tap on link preview in conversation view
    And I tap on Like on edit menu
    And I tap toolbox of the recent message
    Then I see "<Name>" on the message toolbox in conversation view

    Examples:
      | Name      | Contact   | Picture     | Link             |
      | user1Name | user2Name | testing.jpg | https://wire.com |
