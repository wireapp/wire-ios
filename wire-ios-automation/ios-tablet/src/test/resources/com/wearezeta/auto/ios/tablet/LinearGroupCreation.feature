Feature: Linear Group Conversation

  @C652408 @rc @regression @groupcreation @landscape
  Scenario Outline: Teams: I want to create a group conversation with the linear flow
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And I sign in user <TeamOwner> with fast login
    When I open search screen
    When I open create group screen
    And I enter group name "<GroupName>" on New Group page
    And I tap Next button on New Group page
    And I select search result item <Member1> on Add People page
    And I type "<Member2>" in search input field on Add People page
    And I select search result item <Member2> on Add People page
    And I tap Create button on Add People page
    Then I see "<NewIntroductionMessage> <GroupName>" system message in the conversation view
    And I see conversation <GroupName> in conversations list

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName | GroupName | NewIntroductionMessage       |
      | user1Name | user2Name | user3Name | Lollipop | FunFun    | You started the conversation |

  @C652409 @regression @landscape @groupcreation
  Scenario Outline: Teams: I want to create a conversation with myself only
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> is me
    And I sign in user <TeamOwner> with fast login
    When I open search screen
    When I open create group screen
    And I enter group name "  <GroupName>  " on New Group page
    And I tap Next button on New Group page
    Then I see "Everyone is here" label on Add People page
    When I tap Skip button on Add People page
    And I see "<NewIntroductionMessage> <GroupName>" system message in the conversation view
    Then I see conversation <GroupName> in conversations list
    And I do not see a status for conversations list item <GroupName>

    Examples:
      | TeamOwner | TeamName        | GroupName     | NewIntroductionMessage       |
      | user1Name | Tough Seahorses | Rainbow Swipe | You started the conversation |

  @C662714 @regression @groupcreation @guestrooms @landscape
  Scenario Outline: Teams: I want to see no guests in group details after selecting them in linear group creation but switching allow guests OFF [LANDSCAPE]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And There is personal account user <Guest>
    And User Myself is connected to <Guest>
    And I sign in user <TeamOwner> with fast login
    When I open search screen
    When I open create group screen
    And I enter group name "<GroupName>" on New Group page
    And I tap Next button on New Group page
    And I select search result item <Member1> on Add People page
    And I select search result item <Member2> on Add People page
    And I select search result item <Guest> on Add People page
    And I tap Back button on Add People page
    And I expand conversation options on New Group page
    And I switch Allow Guests toggle on New Group page
    And I tap Next button on New Group page
    Then I see the count of selected participants is 2 on Add People page
    When I tap Create button on Add People page
    And I open group conversation details
    Then I do not see participant name <Guest> on Group Details page

    Examples:
      | TeamOwner | Member1   | Member2   | Guest     | TeamName      | GroupName         |
      | user1Name | user2Name | user3Name | user4Name | Follow a flow | Meditation Meetup |
