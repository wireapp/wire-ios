Feature: Linear Group Conversation

  @TC-5927 @TC-6459 @TC-5545 @regression @groupcreation @readReceipts @smoke @grouplimit @folders
  Scenario Outline: Teams: I can create a group conversation with the linear flow
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And I sign in user <TeamOwner> with fast login
    And I accept alert if visible
    And  I open search screen
    And I open create group screen
    And I see max <maxLimit> participant limit on New Group page
    And I enter group name "<GroupName>" on New Group page
   # Then I verify the value of Read Receipts equals to on on New Group page
    When I tap Next button on New Group page
    And I type "<Member1>" in search input field on Add People page
    And I select search result item <Member1> on Add People page
    And I type "<Member2>" in search input field on Add People page
    And I select search result item <Member2> on Add People page
    And I tap Create button on Add People page
    Then I see "<NewIntroductionMessage> <GroupName>" system message in the conversation view
    And I navigate back to conversations list
    And I see conversation <GroupName> in conversations list


    Examples:
      | TeamOwner | Member1   | Member2   | TeamName | GroupName | NewIntroductionMessage       | DefaultConversationOptions                  | maxLimit |
      | user1Name | user2Name | user3Name | Lollipop | FunFun    | You started the conversation | Guests: On, Services: On, Read receipts: On | 500      |
