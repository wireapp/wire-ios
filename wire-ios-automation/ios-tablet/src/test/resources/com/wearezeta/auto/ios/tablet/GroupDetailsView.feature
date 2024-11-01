Feature: Group Details

  @C2715 @regression @rc @landscape
  Scenario Outline: I want to start group chat from 1:1 conversation [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>,<Contact3>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    And I open conversation details
    When I tap Create Group button on Single user profile page
    And I enter group name "<GroupName>" on New Group page
    And I tap Next button on New Group page
    And I select search result item <Contact2> on Add People page
    And I select search result item <Contact3> on Add People page
    And I tap Create button on Add People page
    Then I see conversation <GroupName> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | GroupName |
      | user1Name | user2Name | user3Name | user4Name | Blabla    |

  @C2728 @rc @regression @landscape
  Scenario Outline: I want to verify editing the conversation name [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    Then I do not see Guest Options on Group Details page
    When I change group conversation name to "<ChatName>" on Group Details page
    And I tap X button on Group Details page
    Then I see "You renamed the conversation" system message in the conversation view
    And I see conversation <ChatName> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | ChatName |
      | user1Name | user2Name | user3Name | RenameGroup   | NewName  |

  @C2717 @rc @regression @landscape
  Scenario Outline: I want to verify correct group info page information [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    When I open group conversation details
    Then I see conversation name "<GroupChatName>" on Group Details page
    And I see <ParticipantsNumber> participants avatars on Group Details page

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | ParticipantsNumber |
      | user1Name | user2Name | user3Name | GroupInfo     | 3                  |

  @C2725 @regression @landscape
  Scenario Outline: I want to verify length limit for group conversation name [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    When I open group conversation details
    Then I see conversation name "<GroupChatName>" on Group Details page
    When I try to change group conversation name to random with length <ActualLength> on Group Details page
    Then I see the length of group conversation name equals to <ExpectedLength> on Group Details page

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | ActualLength | ExpectedLength |
      | user1Name | user2Name | user3Name | TESTCHAT      | 70           | 64             |

    ############################
    #### CONVERSATION ROLES ####
    ############################

  @C825942 @C825946 @unstable @groupdetails @landscape @conversationRoles
  Scenario Outline: I want to see the See All Button on the Admins section when there are more than 5 Admins
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6> to team <TeamName> with role Member
    And User <TeamOwner> adds users <External> to team <TeamName> with role Partner
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6>,<External> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I see conversations list
    And User <TeamOwner> changes users <Member1>,<Member2>,<Member3>,<Member4>,<Member5> to role Admin for conversation "<ConversationName>"
    And I open conversation "<ConversationName>" in conversation list
    When I open group conversation details
    Then I do not see the Members section on Conversation Details page
    And I do not see user <Member6> in the Admins section
    And I see the Show All button in the Admins section
    #  I want to see External icon for External in Members section
    When I tap the Show All button
    Then I see external indicator for user <External> on People page

    Examples:
      | TeamOwner | Member1   | Member2   | Member3   | Member4   | Member5   | Member6   | External  | TeamName | ConversationName |
      | user1Name | user2Name | user3Name | user4Name | user5Name | user6Name | user7Name | user8Name | Hero     | Lara Croft       |

  @C825945 @C825949 @regression @groupDetails @landscape @conversationRoles
  Scenario Outline: I want to see the Admin and Member sections when there are admins and members in the conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6>,<Member7> to team <TeamName> with role Member
    And User <Member1> is me
    And User <Member1> has conversation <ConversationName> with <TeamOwner>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6>,<Member7> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I swipe up on Group Details page
    When I tap the Show All button
    Then I see Admins section header on People page
    And I see Members section header on People page
    # I should not be able to tap on my own profile as a Admin
    When I tap on user <Member1> on People page
    Then I do not see name on Group participant profile page
    And I see user <Member1> in the Admins section on People page

    Examples:
      | TeamOwner | Member1   | Member2   | Member3   | Member4   | Member5   | Member6   | Member7   | TeamName  | ConversationName |
      | user1Name | user2Name | user3Name | user4Name | user5Name | user6Name | user7Name | user8Name | SuperTeam | TeamConvo        |

  @C825943 @C825950 @regression @rc @groupDetails @landscape @conversationRoles
  Scenario Outline: I want to see the Conversation Admin Options as an admin (Timed messages, Guests and Services, read receipts toggle, groupname, add participants, delete group)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <Member1> has conversation <ConversationName> with <TeamOwner> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    When I open group conversation details
    # I want to see my own profile in the Admin section when I create a conversation
    Then I see user <Member1> in the Admins section
    And I see Group Name is enabled on Group Details page
    When I tap Commit button on the keyboard if visible
    And I swipe up on Group Details page
    Then I see Timed Messages option on Group Details page
    And I see Guest Options on Group Details page
    And I see Services Options on Group Details page
    And I see the Read Receipts toggle on Group Details page
    And I see Add People button on Group Details page
    When I tap Open Menu button on Group Details page
    Then I see Delete Group… conversation action button

    Examples:
      | TeamOwner | Member1   | TeamName  | ConversationName |
      | user1Name | user2Name | SuperTeam | TeamConvo        |

  @C825944 @C830247 @regression @groupdetails @landscape @conversationRoles
  Scenario Outline: I want to see the empty admins section when there are no Admins
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> adds users <External> to team <TeamName> with role Partner
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<External> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    When I open group conversation details
    Then I see the participant <External> has External indicator on Group Details page
     # I want to see the external icon on the profile of an external participant
    When I select participant <External> on Group Details page
    Then I see External icon on Group participant profile page

    Examples:
      | TeamOwner | Member1   | External   | TeamName | ConversationName |
      | user1Name | user2Name | user3Name  | Hero     | Lara Croft       |

  @C830244 @regression @groupDetails @landscape @conversationRoles
  Scenario Outline: I should not see delete group button when I am conversation admin but not creator
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And User <TeamOwner> changes users <Member1> to role Admin for conversation "<ConversationName>"
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    When I tap Open Menu button on Group Details page
    Then I do not see Delete Group… conversation action button

    Examples:
      | TeamOwner | Member1   | TeamName  | ConversationName |
      | user1Name | user2Name | SuperTeam | TeamConvo        |

  @C830245 @regression @groupDetails @landscape @conversationRoles
  Scenario Outline: I should not see delete group button when I am creator but not conversation admin
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And User <TeamOwner> changes users <Member1> to role Admin for conversation "<ConversationName>"
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    And I see Delete Group… conversation action button
    And I dismiss popover on iPad
    When User <Member1> changes users <TeamOwner> to role Member for conversation "<ConversationName>"
    And I tap Open Menu button on Group Details page
    Then I do not see Delete Group… conversation action button

    Examples:
      | TeamOwner | Member1   | TeamName  | ConversationName |
      | user1Name | user2Name | SuperTeam | TeamConvo        |