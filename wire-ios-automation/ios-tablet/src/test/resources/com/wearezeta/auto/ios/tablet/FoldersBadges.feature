Feature: Folders Badges

  @C823833 @C823837 @regression @rc @folders @foldersBadges @landscape
  Scenario Outline: I want to see correct number of unread conversations in folder bar
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member2> has 1:1 conversation with <Member1> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I opened the filters
    # Open this conversation so we won't affect the badge for conversations we want to check
    And I open conversation "<Member2>" in Folder view
    When User <TeamOwner> sends 6 default messages to conversation <ConversationName>
    Then I see unread conversations badge is 1 for folder "Groups"
    When User <TeamOwner> sends 4 default messages to conversation <Member1>
    Then I see unread conversations badge is 1 for folder "People"
    # I want to see counter increase when I add an unread conversation to folder
    When User <Member1> adds conversation "<TeamOwner>" to <FolderName> folder
    Then I see unread conversations badge is 1 for folder "<FolderName>"
    When User <Member1> adds conversation "<ConversationName>" to <FolderName> folder
    Then I see unread conversations badge is 2 for folder "<FolderName>"

    Examples:
      | TeamOwner | TeamName | Member1   | Member2   | ConversationName | FolderName |
      | user1Name | Hero     | user2Name | user3Name | Lara Croft       | NewFolder  |

  @C823834 @regression @folders @foldersBadges @landscape
  Scenario Outline: I should not see number in folder title when there are no unread conversations
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And I sign in user <Member1> with fast login
    When I opened the filters
    Then I do not see unread conversations badge for folder "People"
    And I do not see unread conversations badge for folder "Groups"
    When User <Member1> adds conversation "<Member2>" to <FolderName> folder
    And User <Member1> adds conversation "<ConversationName>" to <FolderName> folder
    Then I do not see unread conversations badge for folder "<FolderName>"

    Examples:
      | TeamOwner | TeamName | Member1   | Member2   | ConversationName  | FolderName |
      | user1Name | hero     | user2Name | user3Name | Wario             | NewFolder  |

  @C823835 @knownbug @folders @foldersBadges
  Scenario Outline: I want to see counter decrease when I read a conversation BUG: ZIOS-12522
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName2> with <Member1>,<Member2> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I opened the filters
    And User <TeamOwner> sends 6 default messages to conversation <ConversationName>
    And User <TeamOwner> sends 2 default messages to conversation <ConversationName2>
    And I see unread conversations badge is 2 for folder "Groups"
    When I open group conversation "<ConversationName>" in Folder view
    Then I see unread conversations badge is 1 for folder "Groups"

    Examples:
      | TeamOwner | TeamName | Member1   | Member2   | ConversationName | ConversationName2 |
      | user1Name | Hero     | user2Name | user3Name | Ezio Auditore    | My favorite convo |

  @C823836 @rc @regression @folders @foldersBadges @landscape
  Scenario Outline: I want to see counter decrease in Favourites when reading that conversation in different folder
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName> with <Member1> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName2> with <Member1>,<Member2> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I opened the filters
    # Open this conversation so we won't affect the badge for conversations we want to check
    And I open conversation "<TeamOwner>" in Folder view
    And User <Member1> adds conversation "<ConversationName>" to Favorites
    And User <Member1> adds conversation "<ConversationName2>" to Favorites
    And User <TeamOwner> sends 1 default messages to conversation <ConversationName>
    And User <TeamOwner> sends 1 default messages to conversation <ConversationName2>
    And I see unread conversations badge is 2 for folder "Favorites"
    When I collapse Favorites folder
    And I open group conversation "<ConversationName>" in Folder view
    Then I see unread conversations badge is 1 for folder "Favorites"
    And I see unread conversations badge is 1 for folder "Groups"

    Examples:
      | TeamOwner | TeamName | Member1   | Member2   | ConversationName | ConversationName2 |
      | user1Name | Villain  | user2Name | user3Name | Donkey Kong      | My favorite convo |
