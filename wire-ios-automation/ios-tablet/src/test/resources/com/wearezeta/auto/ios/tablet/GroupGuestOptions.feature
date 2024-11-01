Feature: Guest Options

  @C663642 @regression @guestrooms @landscape
  Scenario Outline: Teams: I want to see team members and connections on Add People page if the guest toggle is ON
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And There is personal account user <Guest>
    And User Myself is connected to <Guest>
    And User <TeamOwner> has conversation <GroupName> with <Member1> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I open group conversation "<GroupName>" in conversation list
    And I open group conversation details
    When I tap Guest Options on Group Details page
    Then I verify the value of Allow Guests equals to "1" on Guest Options page
    And I tap Back button on Guest Options page
    When I tap Add People button on Group Details page
    Then I see search result item <Guest> on Group Add People page

    Examples:
      | TeamOwner | Member1   | Guest     | TeamName | GroupName      |
      | user1Name | user2Name | user3Name | Hope     | Trip to Africa |

  @C662713 @regression @guestrooms
  Scenario Outline: Teams: I want to see 'The conversation has guests' banner if there are guests in the conversation [LANDSCAPE]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <GroupName> with <Member1> in team <TeamName>
    And Team user <TeamOwner> allows guests in conversation <GroupName>
    And I sign in user <TeamOwner> with fast login
    And I am signed in properly
    And Team user <TeamOwner> invites wireless user <Wireless1> to conversation <GroupName>
    When I open group conversation "<GroupName>" in conversation list
    Then I see Has Guests banner in conversation view
    When User <Wireless1> leaves group chat <GroupName>
    Then I see "<Wireless1> left" system message in the conversation view
    And I do not see Has Guests banner in conversation view

    Examples:
      | TeamOwner | Member1   | Wireless1 | TeamName | GroupName         |
      | user1Name | user2Name | user3Name | Indians  | Trip to New World |
