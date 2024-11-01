Feature: Conversation List

  @C2530 @regression @rc @landscape
  Scenario Outline: I want to verify archive a conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact>,<Contact2>
    And I sign in user <Name> with fast login
    When I swipe right on conversation <Contact> in Conversations view
    And I tap Archive conversation action button
    Then I do not see conversation <Contact> in conversations list
    And I open archived conversations
    Then I see conversation <Contact> in conversations list

    Examples:
      | Name      | Contact   | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2529 @regression @landscape
  Scenario Outline: I want to Unarchive conversation [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <ArchivedUser>
    And User Myself archives conversation <ArchivedUser>
    And I sign in user <Name> with fast login
    And I open archived conversations
    And I open conversation "<ArchivedUser>" in conversation list
    Then I see the name of the first conversation is <ArchivedUser>

    Examples:
      | Name      | ArchivedUser |
      | user1Name | user2Name    |

  @C2533 @regression
  Scenario Outline: I want to verify Ping animation in the conversations list [PORTRAIT]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User adds the following device: {"<Contact>": [{}]}
    And User Myself removes their avatar picture
    And I sign in user <Name> with fast login
    And I rotate UI to portrait
    And I do not see a status for conversations list item <Contact>
    When User <Contact> pings conversation Myself
    And I see the name of the first conversation is <Contact>
    Then I see status of conversations list item <Contact> is "Pinged"

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2508 @regression @landscape
  Scenario Outline: I want to verify conversations are sorted according to most recent activity [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User <Name> is connected to <Contact>,<Contact2>,<Contact3>
    And Users add the following devices: {"<Contact>": [{}], "<Contact3>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends <Number> default messages to conversation Myself
    And User <Contact3> sends <Number> default messages to conversation Myself
    And I see conversations list
    And I see the name of the first conversation is <Contact3>
    When User <Contact2> pings conversation <Name>
    And I wait for 5 seconds
    Then I see the name of the first conversation is <Contact2>
    When User <Contact> sends 1 image file <Picture> to conversation Myself
    And I wait for 5 seconds
    Then I see the name of the first conversation is <Contact>

    Examples:
      | Name      | Contact   | Contact2  | Contact3  | Number | Picture     |
      | user1Name | user2Name | user3name | user4name | 2      | testing.jpg |

  @C2509 @regression @rc @landscape
  Scenario Outline: I want to verify inbox area displaying in case of new incoming connection requests [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And I sign in user <Name> with fast login
    And I see conversations list
    When I do not see Pending request link in conversations list
    And User <Contact> sent connection request to Me
    And I tap Incoming Pending Requests item in conversations list
    Then I see Connect button on Connection Inbox page
    And I see name "<Contact>" on Connection Inbox page

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2532 @unstable
  Scenario Outline: I want to verify missed call indicator appearance in conversation list [PORTRAIT]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact>,<Contact1>
    And User Myself removes their avatar picture
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And Users add the following devices: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    When I do not see a status for conversations list item <Contact1>
    And <Contact> calls me
    And <Contact> stops outgoing call to me
    And I wait for 5 seconds
    And I see status of conversations list item <Contact> is "Missed call"
    And User <Contact1> sends <Number> default messages to conversation Myself
    Then I see status of conversations list item <Contact> is "Missed call"

    Examples:
      | Name      | Contact   | Contact1  | Number | CallBackend |
      | user1Name | user2Name | user3Name | 2      | chrome      |

  @C2558 @regression @landscape
  Scenario Outline: I want to verify action menu is opened on swipe right on the group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I swipe right on conversation <GroupChatName> in Conversations view
    Then I see Mute conversation action button
    And I see Archive conversation action button
    And I see Clear Content… conversation action button
    And I see Leave Group… conversation action button

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName  |
      | user1Name | user2Name | user3name | ActionMenuChat |

  @C2561 @regression @landscape
  Scenario Outline: I want to verify action menu is opened on swipe right on 1to1 conversation [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I swipe right on conversation <Contact> in Conversations view
    Then I see Mute conversation action button
    And I see Archive conversation action button
    And I see Clear Content… conversation action button
    And I see Block… conversation action button

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2553 @rc @regression @landscape
  Scenario Outline: I want to verify posting in a group conversation without content [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And Users add the following devices: {"<Contact1>": [{}], "Myself": [{}]}
    And I sign in user <Name> with fast login
    And I see conversations list
    And User Myself pings conversation <GroupChatName>
    And User Myself sends 1 default message to conversation <GroupChatName>
    And User <Contact1> sends 1 default message to conversation <GroupChatName>
    And User Myself sends 1 image file <Image> to conversation <GroupChatName>
    When I swipe right on conversation <GroupChatName> in Conversations view
    And I tap Clear Content… conversation action button
    And I tap Clear conversation action button
    Then I do not see conversation <GroupChatName> in conversations list
    When I open search screen
    And I accept alert if visible
    And I type "<GroupChatName>" in Search UI input field
    And I tap on conversation <GroupChatName> in search result
    Then I see 0 conversation entries
    When I type the default message and send it
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | Image       |
      | user1Name | user2Name | user3Name | ForDeletion   | testing.jpg |

  @C2551 @regression @landscape
  Scenario Outline: I want to verify removing the content and leaving from the group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User adds the following device: {"Myself": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself sends 1 default message to conversation <GroupChatName>
    When I swipe right on conversation <GroupChatName> in Conversations view
    And I tap Clear Content… conversation action button
    And I tap Clear and leave conversation action button
    When I open search screen
    And I accept alert if visible
    And I type "<GroupChatName>" in Search UI input field
    Then I see the conversation "<GroupChatName>" does not exist in Search results
    When I tap X button on Search UI page
    Then I do not see conversation <GroupChatName> in conversations list
    And I do not see Archive button at the bottom of conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | ForDeletion   |

  @C2555 @regression @landscape
  Scenario Outline: I want to verify deleting the history from kicked out conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User <Name> changes users <Contact1> to role Admin for conversation "<GroupChatName>"
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> removes user Myself from group conversation <GroupChatName>
    And I swipe right on conversation <GroupChatName> in Conversations view
    And I see Archive conversation action button
    And I tap Clear Content… conversation action button
    When I tap Clear conversation action button
    Then I do not see conversation <GroupChatName> in conversations list
    And I do not see Archive button at the bottom of conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | KICKCHAT      |

  @C2541 @regression @landscape
  Scenario Outline: I want to verify blocking person from action menu [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    When I swipe right on conversation <Contact> in Conversations view
    And I tap Block… conversation action button
    And I confirm conversation action
    Then I do not see conversation <Contact> in conversations list
    And I do not see Archive button at the bottom of conversations list
    And I wait until <Contact> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact>" in Search UI input field
    Then I see the conversation "<Contact>" exists in Search results

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2536 @regression @rc @landscape
  Scenario Outline: I want to verify messages are marked read after opening a conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User adds the following device: {"<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I open conversation "<Contact2>" in conversation list
    When User <Contact1> sends 10 default messages to conversation Myself
    And I open conversation "<Contact1>" in conversation list
    Then I do not see a status for conversations list item <Contact1>

    Examples:
      | Name      | Contact1  | Contact2  |
      | user1Name | user2Name | user3Name |
