Feature: Search

  @C2788 @rc @regression @landscape
  Scenario Outline: I want to verify search by email does not work [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And I sign in user <Name> with fast login
    When I open search screen
    And I accept alert if visible
    And I type "<ContactEmail>" in Search UI input field
    Then I see the conversation "<ContactName>" does not exist in Search results

    Examples:
      | Name      | ContactEmail | ContactName |
      | user1Name | user2Email   | user2Name   |

  @C2789 @rc @regression @landscape
  Scenario Outline: I want to verify search by name [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <IntermediateContact>
    And User <Contact> is connected to <IntermediateContact>
    And I sign in user <Name> with fast login
    And I wait until <Contact> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact>" in Search UI input field
    Then I see the conversation "<Contact>" exists in Search results

    Examples:
      | Name      | Contact   | IntermediateContact |
      | user1Name | user2Name | user3Name           |

  @C2839 @regression @landscape
  Scenario Outline: I want to start 1:1 chat with users from Top Connections [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to all other users
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 default message to conversation Myself
    And I see conversations list
    When I open search screen
    And I accept alert if visible
    When I select 1 avatar from Top connections
    Then I see conversation view page

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2790 @rc @regression @landscape
  Scenario Outline: I want to unblock someone from search list [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User <Contact> is connected to <Name>
    And User <Name> blocks user <Contact>
    And I sign in user <Name> with fast login
    When I do not see conversation <Contact> in conversations list
    And I wait until <Contact> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact>" in Search UI input field
    And I tap the instant connect button next to <Contact>
    And I tap X button on Search UI page
    And I open conversation "<Contact>" in conversation list
    And I type the default message and send it
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2792 @rc @regression @landscape
  Scenario Outline: I want to search by second name (something after space) [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User <Contact> is connected to <Name>
    And User <Contact> changes name to <FirstName> <LastName>
    And I sign in user <Name> with fast login
    And I wait until <LastName> exists in backend search results
    When I open search screen
    And I accept alert if visible
    When I type "<LastName>" in Search UI input field
    Then I see the conversation "<FirstName> <LastName>" exists in Search results

    Examples:
      | Name      | Contact   | FirstName | LastName |
      | user1Name | user2Name | FirstName | LastName |

  @C2795 @rc @regression @landscape
    Scenario Outline: I want to search by part of the name [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User <Contact> is connected to <Name>
    And I sign in user <Name> with fast login
    And I wait until <Contact> exists in backend search results
    When I open search screen
    And I accept alert if visible
    When I type first <LettersCount> letters of user name "<Contact>" into Search UI input field
    Then I see the conversation "<Contact>" exists in Search results

    Examples:
      | Name      | Contact   | LettersCount |
      | user1Name | user2Name | 7            |

  @C2818 @regression @landscape
  Scenario Outline: I want to verify opening conversation from Top People [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to all other users
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 default message to conversation Myself
    # Wait for message delivery
    And I wait for 3 seconds
    When I open search screen
    And I accept alert if visible
    When I tap the 1st avatar in Top connections
    Then I see conversation view page

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |
