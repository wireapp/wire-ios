Feature: Deletegroup

  @C798777 @deletegroup @landscape @regression @rc
  Scenario Outline: I want to delete a group as the Group Creator (landscape)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    And I open group conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Delete Group… conversation action button
    Then I see action sheet contains text "<AlertString>"
    When I tap Delete Group conversation action button
    Then I do not see conversation <ConversationName> in conversations list

    Examples:
      | TeamOwner | Member1   | TeamName | ConversationName | AlertString                |
      | user1Name | user2Name | Zoo      | traag            | Delete group conversation? |

  @C798790 @deletegroup @landscape @regression
  Scenario Outline: I should not see group as guest after it was deleted
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And There are personal account users <Guest1>
    And User <Guest1> is connected to <TeamOwner>,<Member2>,<Member1>
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2>,<Guest1> in team <TeamName>
    And User <Guest1> is me
    And I sign in user <Guest1> with fast login
    And I see conversation <ConversationName> in conversations list
    And Group admin user <TeamOwner> deletes conversation <ConversationName>
    And I do not see conversation <ConversationName> in conversations list
    When I open search screen
    And I accept alert if visible
    When I type "<ConversationName>" in Search UI input field
    Then I see the conversation "<ConversationName>" does not exist in Search results

    Examples:
      | TeamOwner |  TeamName  | Member1   | Member2   | ConversationName | Guest1    |
      | user1Name |  kaas      | user2Name | user3Name | deleteThisGroup  | user4Name |
