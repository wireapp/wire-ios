Feature: ContactsUI

  @C2499 @regression @landscape
  Scenario Outline: I want to verify blocked users are not displayed in the Contacts UI [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> blocks user <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    And I do not see conversation <Contact> in conversations list
    And I open search screen
    And I accept alert if visible
    And I tap Send Invite button on Search UI page
    And I see ContactsUI page
    When I input user name <Contact> in search on ContactsUI
    Then I do not see contact <Contact> in ContactsUI page list

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2493 @regression @landscape
  Scenario Outline: I want to verify opening existing conversation from Contacts UI [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to all other users
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open search screen
    And I accept alert if visible
    And I tap Send Invite button on Search UI page
    When I tap Open button next to user name <Contact> on ContactsUI
    Then I see the conversation with <Contact> is opened

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |
