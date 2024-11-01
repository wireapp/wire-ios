Feature: Link Preview

  @C169217 @regression @landscape
  Scenario Outline: I want to verify preview is shown for sent link (link only)
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    When I type the "<Link>" message and send it
    Then I see link preview container in the conversation view

    Examples:
      | Name      | Contact   | Link             |
      | user1Name | user2Name | https://wire.com |

  @C169219 @rc @regression @landscape
  Scenario Outline: I want to verify deleting link preview
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    And I type the "<Link>" message and send it
    And I tap Hide keyboard button
    And I see link preview container in the conversation view
    When I long tap on link preview in conversation view
    And I tap on Delete on edit menu
    And I select Delete for Me item from Delete menu
    Then I do not see link preview container in the conversation view

    Examples:
      | Name      | Contact   | Link             |
      | user1Name | user2Name | https://wire.com |

  @C169218 @rc @regression @landscape
  Scenario Outline: I want to verify preview is shown for received link
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 "<Link>" message to conversation Myself
    And I open conversation "<Contact>" in conversation list
    Then I see link preview container in the conversation view

    Examples:
      | Name      | Contact   | Link             |
      | user1Name | user2Name | https://wire.com |
