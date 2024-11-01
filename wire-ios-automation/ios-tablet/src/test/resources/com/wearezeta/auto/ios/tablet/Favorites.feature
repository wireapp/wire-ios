Feature: Favorites

  @C814818 @regression @rc @folders @favorites @landscape
  Scenario Outline: I want to add a conversation to favorites from list/folder view
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    When I swipe right on conversation <ConversationName> in Conversations view
    And I tap Add to Favorites conversation action button
    And I opened the filters
    Then I see Favorites folder in Folder view
    And I see conversation <ConversationName> in Favorites folder
    And I see Groups folder in Folder view
    And I see conversation <ConversationName> in Groups folder
    When I swipe right on conversation <ConversationName> in Folder view
    And I tap Remove from Favorites conversation action button
    Then I do not see conversation <ConversationName> in Favorites folder
    And I see conversation <ConversationName> in Groups folder

    Examples:
      | TeamOwner | TeamName  | Member1   | ConversationName  |
      | user1Name | Cherished | user2Name | Talk about things |