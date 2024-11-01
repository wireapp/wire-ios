Feature: Partner role

  @C743163 @C743164 @regression @partner @landscape
  Scenario Outline: I want to see only inviter in start UI
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> adds users <Partner1>, <Partner2> to team <TeamName> with role Partner
    And User <Partner1> is me
    And I sign in user <Partner1> with fast login
    When I open search screen
    And I accept alert if visible
    Then I do not see contact <TeamOwner> in ContactsUI page list
    And I do not see contact <Member1> in ContactsUI page list
    And I do not see contact <Partner2> in ContactsUI page list
    Then I do not see Create Group button on Search UI page
    And I do not see Create Guest Room button on Search UI page

    Examples:
      | TeamOwner | Member1   | Partner1  | Partner2  | TeamName |
      | user1Name | user2Name | user3Name | user4Name | Lalilama |
