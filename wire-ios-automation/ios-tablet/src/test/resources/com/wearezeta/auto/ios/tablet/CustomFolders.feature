Feature: Custom Folders

  @C815087 @regression @folders @customFolders @landscape
  Scenario Outline: I want to move a 1:1 conversation to a new custom folder
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I see conversations list
    When I swipe right on conversation <TeamOwner> in Conversations view
    And I tap Move to… conversation action button
    And I see Move to Custom Folder page
    And I tap Create button on Custom Folder page
    And I enter Folder name "<FolderName>" on New Folder page
    And I tap Create button on New Folder page
    And I see conversations list
    And I opened the filters
    Then I see custom folder <FolderName> in Folder view
    And I see conversation <TeamOwner> in custom folder <FolderName>
    # C815087 Move 1:1 into existing folder
    When I swipe right on conversation <Member2> in Folder view
    And I tap Move to… conversation action button
    And I tap folder "<FolderName>" on Custom Folder page
    And I collapse custom folder <FolderName>
    And I expand custom folder <FolderName>
    Then I see conversation <Member2> in custom folder <FolderName>

    Examples:
      | TeamOwner | TeamName   | Member1   | FolderName | Member2   |
      | user1Name | ReneFroger | user2Name | oneOnOne   | user3Name |

  @C815088 @C815089 @regression @rc @folders @customFolders @landscape
  Scenario Outline: I want to move a group conversation to a new/existing custom folder
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName2> with <Member1>,<Member2> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I see conversations list
    When I swipe right on conversation <ConversationName> in Conversations view
    And I tap Move to… conversation action button
    And I see Move to Custom Folder page
    And I tap Create button on Custom Folder page
    And I enter Folder name "<FolderName>" on New Folder page
    And I tap Create button on New Folder page
    And I see conversations list
    And I opened the filters
    Then I see custom folder <FolderName> in Folder view
    And I see conversation <ConversationName> in custom folder <FolderName>
    # C815089 Move group into existing folder
    When I swipe right on conversation <ConversationName2> in Folder view
    And I tap Move to… conversation action button
    And I tap folder "<FolderName>" on Custom Folder page
    And I collapse custom folder <FolderName>
    And I expand custom folder <FolderName>
    Then I see conversation <ConversationName2> in custom folder <FolderName>

    Examples:
      | TeamOwner | TeamName   | Member1   | FolderName | ConversationName | ConversationName2 | Member2   |
      | user1Name | FunFunFun  | user2Name | oneOnOne   | plezier plezier  | nogMeerPlezier    | user3Name |

  @C815090 @regression @folders @customFolders @landscape
  Scenario Outline: I want to see custom folder removed when last conversation is removed
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I see conversations list
    And User <Member1> adds conversation "<TeamOwner>" to <FolderName> folder
    And I opened the filters
    And I see custom folder <FolderName> in Folder view
    When I swipe right on conversation <TeamOwner> in Conversations view
    And I tap Remove from "<FolderName>" conversation action button
    Then I do not see custom folder <FolderName> in Folder view
    And I see conversation <TeamOwner> in People folder

    Examples:
      | TeamOwner | TeamName   | Member1   | FolderName |
      | user1Name | ReneFroger | user2Name | oneOnOne   |

  @C815091 @regression @folders @customFolders @landscape
  Scenario Outline: I want to move a conversation from one custom folder to another
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And User <Member1> is me
    And I sign in user <Member1> with fast login
    And I see conversations list
    And User <Member1> adds conversation "<TeamOwner>" to <FolderName> folder
    And User <Member1> adds conversation "<ConversationName>" to <FolderName2> folder
    And I opened the filters
    And I see custom folder <FolderName> in Folder view
    When I swipe right on conversation <TeamOwner> in Conversations view
    And I tap Move to… conversation action button
    And I tap folder "<FolderName2>" on Custom Folder page
#    force refresh locators
    And I restart Wire
    And I accept alert
    Then I see conversation <TeamOwner> in custom folder <FolderName2>
    And I do not see custom folder <FolderName> in Folder view
    And I do not see conversation <TeamOwner> in People folder
    When User <Member1> adds conversation "<ConversationName>" to <FolderName> folder
#    force refresh locators
    And I restart Wire
    Then I see custom folder <FolderName> in Folder view
    And I do not see conversation <ConversationName> in Groups folder
    And I see conversation <ConversationName> in custom folder <FolderName>

    Examples:
      | TeamOwner | TeamName   | Member1   | FolderName | FolderName2 | ConversationName | Member2   |
      | user1Name | ReneFroger | user2Name | oneOnOne   | twoTwoTwo   | FutureAllISee    | user3Name |

  @C815092 @regression @folders @customFolders @landscape
  Scenario Outline: I want to see ping icon, unread icon and secondary line for all conversations in a custom folder
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <Member1> has conversation <ConversationName> with <TeamOwner>,<Member2> in team <TeamName>
    And User <Member1> has conversation <ConversationName2> with <TeamOwner>,<Member2> in team <TeamName>
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <Member1> has 1:1 conversation with <Member2> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And User <Member1> adds conversation "<TeamOwner>" to <FolderName> folder
    And User <Member1> adds conversation "<ConversationName>" to <FolderName> folder
    And User <Member1> adds conversation "<ConversationName2>" to <FolderName> folder
    And I opened the filters
    And I open 1:1 conversation "<Member2>" in Folder view
    And I see conversation <TeamOwner> in custom folder <FolderName>
    When User <TeamOwner> sends 2 default message to conversation <ConversationName>
    Then I see the secondary line of Folder view conversation item <ConversationName> is "<TeamOwner>"
    And I see status of Folder view conversation item <ConversationName> is 2
    When User <TeamOwner> sends 1 message "Hello @<Member1>" with mention to conversation <ConversationName>
    Then I see the secondary line of Folder view conversation item <ConversationName> is "1 mention, 2 messages"
    And I see status of Folder view conversation item <ConversationName> is You are mentioned
    When User <TeamOwner> pings conversation <ConversationName>
    Then I see status of Folder view conversation item <ConversationName> is You are mentioned
    And I see the secondary line of Folder view conversation item <ConversationName> is "1 mention, 1 ping, 2 messages"
    When User <TeamOwner> pings conversation <ConversationName2>
    Then I see status of Folder view conversation item <ConversationName2> is ping
    When User <TeamOwner> sends 1 message "Hello @<Member1>" with mention to conversation <Member1>
    Then I see status of Folder view conversation item <TeamOwner> is You are mentioned

    Examples:
      | TeamOwner | TeamName        | Member1    | ConversationName | FolderName | ConversationName2 | Member2   |
      | user1Name | White Chocolate | user2Name  | No_raisin        | MafKaas    | anotherConvoHere  | user3Name |