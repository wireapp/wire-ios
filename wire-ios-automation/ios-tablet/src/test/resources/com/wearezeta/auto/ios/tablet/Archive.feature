Feature: Archive

  @C2389 @regression @landscape
  Scenario Outline: I want to unarchive by receiving data [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <ArchivedUser>
    And Users add the following devices: {"Myself": [{}], "<ArchivedUser>": [{}]}
    And User Myself archives conversation <ArchivedUser>
    And User <ArchivedUser> sets the unique username
    And <ArchivedUser> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I do not see conversation <ArchivedUser> in conversations list
    And User <ArchivedUser> sends 1 default message to conversation Myself
    # Wait for sync
    And I wait for 3 seconds
    Then I see the name of the first conversation is <ArchivedUser>
    When User Myself archives conversation <ArchivedUser>
    And I do not see conversation <ArchivedUser> in conversations list
    And User <ArchivedUser> sends 1 image file <Picture> to conversation Myself
    Then I see the name of the first conversation is <ArchivedUser>
    When User Myself archives conversation <ArchivedUser>
    And I do not see conversation <ArchivedUser> in conversations list
    And User <ArchivedUser> pings conversation <Name>
    Then I see the name of the first conversation is <ArchivedUser>
    When User Myself archives conversation <ArchivedUser>
    And I do not see conversation <ArchivedUser> in conversations list
    And <ArchivedUser> calls me
    And I see Calling overlay
    And <ArchivedUser> stops outgoing call to me
    Then I see the name of the first conversation is <ArchivedUser>

    Examples:
      | Name      | ArchivedUser | Picture     | CallBackend |
      | user1Name | user2Name    | testing.jpg | chrome      |

  @C2390 @regression @landscape
  Scenario Outline: I want to archived silenced conversation is not unarchived by call [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <ArchivedUser>,<ArchivedUser2>
    And User <ArchivedUser> sets the unique username
    And User <ArchivedUser2> sets the unique username
    And User adds the following devices: {"Myself": [{}]}
    And <ArchivedUser> starts instance using <CallBackend>
    And User Myself mutes conversation <ArchivedUser>
    And User Myself archives conversation <ArchivedUser>
    And User Myself mutes conversation <ArchivedUser2>
    And User Myself archives conversation <ArchivedUser2>
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <ArchivedUser2> sends 1 default message to conversation Myself
    When I do not see conversation <ArchivedUser> in conversations list
    And I open archived conversations
    And I see conversation <ArchivedUser> in conversations list
    And I see conversation <ArchivedUser2> in conversations list
    And I see the name of the first conversation is <ArchivedUser2>
    And I tap close Archive page button
    And <ArchivedUser> calls me
    And I do not see conversation <ArchivedUser> in conversations list
    And <ArchivedUser> stops outgoing call to me
    And I open archived conversations
    And I see conversation <ArchivedUser> in conversations list
    And I see the name of the first conversation is <ArchivedUser>
    Then I see the secondary line in conversations list item <ArchivedUser> is "1 missed call"

    Examples:
      | Name      | ArchivedUser | ArchivedUser2 | CallBackend |
      | user1Name | user2Name    | user3Name     | chrome      |

  @C2392 @regression @landscape
  Scenario Outline: I want to restore from archive after adding to conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User <Name> changes users <Contact1> to role Admin for conversation "<GroupChatName>"
    And User adds the following device: {"<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I swipe right on conversation <GroupChatName> in Conversations view
    And I tap Leave Group… conversation action button
    And I confirm conversation action
    And I do not see conversation <GroupChatName> in conversations list
    When User <Contact1> adds me to group chat <GroupChatName>
    And User <Contact1> sends 1 default message to conversation <GroupChatName>
    Then I see the name of the first conversation is <GroupChatName>

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | LeaveArchive  |

  @C95635 @regression @landscape
  Scenario Outline: I want to archive behaviour when one archive/unarchive a conversation [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <ArchivedUser>
    And Users add the following devices: {"Myself": [{}], "<ArchivedUser>": [{}]}
    And User Myself archives conversation <ArchivedUser>
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <ArchivedUser> sends 1 default message to conversation Myself
    And I see conversations list
    When I see conversation <ArchivedUser> in conversations list
    Then I do not see Archive button at the bottom of conversations list
    When User Myself archives conversation <ArchivedUser>
    Then I do not see conversation <ArchivedUser> in conversations list
    And I see Archive button at the bottom of conversations list
    And I see EVERYTHING ARCHIVED placeholder in conversations list
    When I open archived conversations
    Then I see conversation <ArchivedUser> in conversations list
    When I swipe right on conversation <ArchivedUser> in Conversations view
    And I tap Unarchive conversation action button
    Then I do not see conversation <ArchivedUser> in conversations list
    When I tap close Archive page button
    Then I see conversation <ArchivedUser> in conversations list
    And I do not see Archive button at the bottom of conversations list
    When I swipe right on conversation <ArchivedUser> in Conversations view
    And I tap Archive conversation action button
    And I do not see conversation <ArchivedUser> in conversations list
    And I see Archive button at the bottom of conversations list
    And User <ArchivedUser> sends 1 default message to conversation Myself
    Then I see conversation <ArchivedUser> in conversations list
    And I do not see Archive button at the bottom of conversations list

    Examples:
      | Name      | ArchivedUser |
      | user1Name | user2Name    |

  @C2733 @rc @regression @landscape
  Scenario Outline: I want to verify archiving conversation from ellipsis menu [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I open conversation details
    And I tap Open Menu button on Single user profile page
    And I tap Archive conversation action button
    Then I do not see conversation <Contact> in conversations list
    And I open archived conversations
    Then I see conversation <Contact> in conversations list

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2388 @regression @landscape
  Scenario Outline: I want to verify archiving silenced conversation [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    When I swipe right on conversation <Contact> in Conversations view
    And I tap Mute conversation action button
    When I swipe right on conversation <Contact> in Conversations view
    And I tap Archive conversation action button
    Then I do not see conversation <Contact> in conversations list
    When User <Contact> sends 1 default message to conversation Myself
    And I do not see conversation <Contact> in conversations list
    And User <Contact> sends 1 image file <Picture> to conversation Myself
    Then I do not see conversation <Contact> in conversations list
    And I open archived conversations
    Then I see conversation <Contact> in conversations list
    And I open conversation "<Contact>" in conversation list
    And I see 1 photo in the conversation view

    Examples:
      | Name      | Contact   | Picture     |
      | user1Name | user2Name | testing.jpg |

  ################################
  # Grouped Conversations        #
  ################################

  @C814722 @regression @archive @folders @landscape
  Scenario Outline: I want to archive and unarchive conversation via Grouped Conversations view
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I opened the filters
    And I swipe right on conversation <TeamOwner> in Conversations view
    # Archive
    When I tap Archive conversation action button
    Then I do not see conversation <TeamOwner> in People folder
    When I open archived conversations
    Then I see conversation <TeamOwner> in archived conversations list
    # Unarchive
    When I open archived conversation "<TeamOwner>"
    And I navigate back to conversations list
    Then I see Folder view
    And I see conversation <TeamOwner> in People folder

    Examples:
      | TeamOwner | Member1   | TeamName |
      | user1Name | user2Name | Chip     |
