Feature: Group Creation

  @TC-4979 @col1
  Scenario Outline: I want to create a group conversation with the linear flow
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    And I open search screen
    And I open create group screen
    And I enter group name "<GroupConversationWithClassified>" on New Group page
    And I tap Next button on New Group page
    And I select search result item <Member1> on Add People page
    And I type "<Member2>" in search input field on Add People page
    And I select search result item <Member2> on Add People page
    And I tap Create button on Add People page
    Then I see "<NewIntroductionMessage> <GroupConversationWithClassified>" system message in the conversation view
    When I navigate back to conversations list
    Then I see conversation <GroupConversationWithClassified> in conversations list


    Examples:
      | TeamOwner |TeamName               | Member1   | Member2   | GroupConversationWithClassified | NewIntroductionMessage       |
      | user1Name | The Classified Domain | user2Name | user3Name | ClassifiedDomainConvo           | You started the conversation |