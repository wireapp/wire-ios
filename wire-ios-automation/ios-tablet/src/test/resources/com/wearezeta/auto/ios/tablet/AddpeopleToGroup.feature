Feature: Group Add Participant

  @C2723 @regression @landscape
  Scenario Outline: I want to add someone to a group conversation [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>,<Contact3>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I select search result item <Contact3> on Group Add People page
    When I tap Add Participants button on Group Add People page
    Then I see <ParticipantsNumber> participants avatars on Group Details page

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | GroupChatName | ParticipantsNumber |
      | user1Name | user2Name | user3Name | user4Name | AddContact    | 4                  |

  @C2724 @regression @landscape
  Scenario Outline: I want to verify displaying only connected users in the search in group chat [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Add People button on Group Details page
    When I type search query "<Contact3>" on Group Add People page
    Then I see "No Results" label on Group Add People page

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | GroupChatName |
      | user1Name | user2Name | user3Name | user3Name | OnlyConnected |
