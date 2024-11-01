Feature: Group Participant View

  @C2716 @rc @regression @landscape
  Scenario Outline: I want to verify removing from group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I select participant <Contact2> on Group Details page
    When I tap Remove From Conversation button on Group participant profile page
    And I confirm conversation action
    Then I do not see participant name <Contact2> on Group Details page

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | RemoveGroup   |

  @C2718 @rc @regression @landscape
  Scenario Outline: I want to check any users personal Details in group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact2>,<ConnectedContact>
    And User Myself has group conversation <GroupChatName> with <Contact2>,<ConnectedContact>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    When I open group conversation details
    And I select participant <Contact2> on Group Details page
    Then I see name "<Contact2>" on Group participant profile page

    Examples:
      | Name      | Contact2  | ConnectedContact | GroupChatName   |
      | user1Name | user2Name | user3Name        | SingleDetailsGroup |

  @C2720 @regression @landscape
  Scenario Outline: I should not start 1:1 with unconnected user in group [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User <GroupCreator> is connected to me
    And User <GroupCreator> is connected to <NonConnectedContact>
    And User <GroupCreator> has group conversation <GroupChatName> with Myself,<NonConnectedContact>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    When I select participant <NonConnectedContact> on Group Details page
    Then I see Connect button on Group participant Pending outgoing connection page

    Examples:
      | Name      | GroupCreator | NonConnectedContact | GroupChatName |
      | user1Name | user2Name    | user3Name           | TESTCHAT      |

  @C2721 @rc @regression @landscape
  Scenario Outline: I want to open 1-to-1 conversation from group conversation details [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact2>,<Contact3>
    And User Myself has group conversation <GroupChatName> with <Contact2>,<Contact3>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I select participant <Contact2> on Group Details page
    When I tap Open Conversation button on Group participant profile page
    And I type the default message and send it
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact2  | Contact3  | GroupChatName |
      | user1Name | user2Name | user3Name | 1on1FromGroup |

  @C2433 @regression @landscape
  Scenario Outline: I want to verify impossibility of starting 1:1 conversation with pending user [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User <Contact1> is connected to <Contact3>,<Contact2>,<Name>
    And User <Contact1> has group conversation <GroupChatName> with <Contact3>,<Contact2>,<Name>
    And User <Contact1> changes users <Name> to role Admin for conversation "<GroupChatName>"
    And User Myself sent connection request to <Contact3>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    When I select participant <Contact3> on Group Details page
    Then I see name "<Contact3>" on Group participant Pending outgoing connection page
    When I tap Open Menu button on Group participant Pending outgoing connection page
    Then I see Remove From Group… conversation action button

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | GroupChatName |
      | user1Name | user2Name | user3Name | user4Name | TESTCHAT      |

  @C662711 @regression @guestrooms @landscape
  Scenario Outline: Teams: I want to remove wireless Guest from the conversation [LANDSCAPE]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> is me
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And Team user <TeamOwner> allows guests in conversation <ConversationName>
    And Team user <TeamOwner> invites wireless user <TemporaryGuest> to conversation <ConversationName>
    And I sign in user <TeamOwner> with fast login
    And I open group conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I see 2 Members label on Group Details page
    And I see 1 Admins label on Group Details page
    And I select participant <TemporaryGuest> on Group Details page
    And I tap Open Menu button on Group participant profile page
    When I tap Remove From Group… conversation action button
    And I tap Remove From Group conversation action button
    Then I do not see participant name <TemporaryGuest> on Group Details page
    When I tap X button on Group Details page
    Then I see "You removed <TemporaryGuest>" system message in the conversation view

    Examples:
      | TeamOwner | TeamName      | Member1   | ConversationName | TemporaryGuest |
      | user1Name | Hacuna Matata | user2Name | Timon & Pumba    | user3Name      |

  @C830246 @C834912 @C834913 @groupparticipantview @landscape @conversationRoles @regression @rc
  Scenario Outline: I want to see the group admin toggle on a participants profile as an admin
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <Member1> has conversation <ConversationName> with <TeamOwner> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    When I select participant <TeamOwner> on Group Details page
    Then I see Admin toggle on Group participant profile page
    # I want to see the group admin icon on participants profile immediately after making conversation member an admin
    When I tap Admin toggle on Group participant profile page
    Then I see Admin icon on Group participant profile page
    # I want to see Remove from group as an admin seeing a participants profile
    And I tap Open Menu button on Group participant profile page
    Then I see Remove From Group… conversation action button

    Examples:
      | TeamOwner | Member1   | TeamName  | ConversationName |
      | user1Name | user2Name | SuperTeam | TeamConvo        |

  @C830248 @groupparticipantview @conversationRoles @landscape @regression
  Scenario Outline: I want to see the group admin icon as a member seeing the group admin profile
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    When I select participant <TeamOwner> on Group Details page
    Then I see Admin icon on Group participant profile page
    And I do not see Admin toggle on Group participant profile page

    Examples:
      | TeamOwner | Member1   | TeamName  | ConversationName |
      | user1Name | user2Name | SuperTeam | TeamConvo        |
