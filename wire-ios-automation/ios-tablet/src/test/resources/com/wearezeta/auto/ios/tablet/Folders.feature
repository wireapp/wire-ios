Feature: Folders

  @C814718 @regression @folders @landscape
  Scenario Outline: I want to see a folder for group conversations when I switch to folder view
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    When I opened the filters
    Then I see Folder view
    And I see Groups folder in Folder view
    And I see conversation <ConversationName> in Groups folder

    Examples:
      | TeamOwner | TeamName   | Member1   | ConversationName  |
      | user1Name | ReneFroger | user2Name | Geer en Goor      |

  @C814719 @regression @folders @landscape
  Scenario Outline: I want to see a folder for 1:1 conversations when I switch to folder view
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I see conversations list
    When I opened the filters
    Then I see People folder in Folder view
    And I see conversation <TeamOwner> in People folder

    Examples:
      | TeamOwner | TeamName   | Member1   |
      | user1Name | ReneFroger | user2Name |

  @C814720 @regression @folders @landscape
  Scenario Outline: I want to see a collapsed folder when I collapse a folder, navigate to all conversations list and press the folder button again
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> is me
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    And I opened the filters
    And I collapse People folder
    And I tap Conversations button in bottom navigation bar
    When I opened the filters
    Then I see People folder is collapsed

    Examples:
      | TeamOwner | TeamName   | Member1   |
      | user1Name | ReneFroger | user2Name |

  @C814721 @regression @folders @landscape
  Scenario Outline: I want to collapse folders
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I see conversations list
    And I opened the filters
    And I see Folder view
    When I collapse People folder
    Then I see People folder is collapsed

    Examples:
      | TeamOwner | TeamName   | Member1   |
      | user1Name | ReneFroger | user2Name |

  @C814723 @regression @folders @landscape @rc
  Scenario Outline: I want to see current conversation stays selected when I switch views
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName1> with <Member1> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName2> with <Member1> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    When I opened the filters
    Then I see conversation <ConversationName> in Groups folder
    And I open group conversation details
    And I see conversation name "<ConversationName>" on Group Details page

    Examples:
      | TeamOwner | TeamName   | Member1   |  ConversationName  | ConversationName1 | ConversationName2 |
      | user1Name | ReneFroger | user2Name |  Geer en Goor      | Hans en grietje   | bert en ernie     |