Feature: Connect

  @C2489 @rc @regression @landscape
  Scenario Outline: I want to verify sending connection request after opening profile by clicking on the name and avatar [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact2>
    And User <Contact2> is connected to <Contact>
    And I sign in user <Name> with fast login
    And I wait until <Contact> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact>" in Search UI input field
    And I tap on conversation <Contact> in search result
    And I tap Connect button on Single user Pending outgoing connection page
    And I tap X button on Single user Pending outgoing connection page
    And I tap X button on Search UI page
    Then I see the name of the first conversation is <Contact>
    When I open conversation "<Contact>" in conversation list
    Then I see the conversation with <Contact> is opened
    And I see Cancel Request button on Single user Pending outgoing connection page

    Examples:
      | Name      | Contact   | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2490 @rc @regression @landscape
  Scenario Outline: I want to send connection request to unconnected participant in a group chat [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <GroupCreator>
    And User <GroupCreator> is connected to <UnconnectedUser>
    And User <GroupCreator> has group conversation <GroupChatName> with <UnconnectedUser>,Myself
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I select participant <UnconnectedUser> on Group Details page
    When I tap Connect button on Single user Pending outgoing connection page
    And I tap Back button on Single user Pending outgoing connection page on iPad
    And I tap X button on Group Details page
    Then I see the name of the first conversation is <UnconnectedUser>

    Examples:
      | Name      | GroupCreator | GroupChatName | UnconnectedUser |
      | user1Name | user2Name    | TESTCHAT      | user3Name       |

  @C2440 @regression @landscape
  Scenario Outline: I want to verify transitions between connection requests (ignoring) [LANDSCAPE]
    Given There are 5 users where <Name> is me
    And User <Contact1> sent connection request to me
    And User <Contact2> sent connection request to me
    And User <Contact3> sent connection request to me
    And User Myself is connected to <Contact4>
    And User <Contact1> is connected to <Contact4>
    And I sign in user <Name> with fast login
    And I am signed in properly
    When I tap Incoming Pending Requests item in conversations list
    And I tap Ignore button on Connection Inbox page
    And I tap Ignore button on Connection Inbox page
    And I tap Ignore button on Connection Inbox page
    And I do not see Pending request link in conversations list
    And I do not see conversation <Contact1> in conversations list
    And I wait until <Contact1> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact1>" in Search UI input field
    And I tap on conversation <Contact1> in search result
    Then I see name "<Contact1>" on Group participant Pending incoming connection page

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | Contact4  |
      | user1Name | user2Name | user3Name | user4Name | user5Name |

  @C2441 @regression @landscape
  Scenario Outline: I want to verify transitions between connection requests (accepting) [LANDSCAPE]
    Given There are 5 users where <Name> is me
    And User <Contact1> sent connection request to me
    And User <Contact2> sent connection request to me
    And User <Contact3> sent connection request to me
    And User Myself is connected to <Contact4>
    And I sign in user <Name> with fast login
    And I am signed in properly
    When I tap Incoming Pending Requests item in conversations list
    And I tap Connect button on Connection Inbox page
    And I tap Connect button on Connection Inbox page
    And I tap Connect button on Connection Inbox page
    Then I do not see Pending request link in conversations list
    And I see conversation <Contact1> in conversations list
    And I see conversation <Contact2> in conversations list
    And I see conversation <Contact3> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | Contact4  |
      | user1Name | user2Name | user3Name | user4Name | user5Name |

  @C2482 @regression @landscape
  Scenario Outline: I want to verify impossibility of starting 1:1 conversation with pending user [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact2>
    And User Me sent connection request to <Contact>
    And I sign in user <Name> with fast login
    When I open conversation "<Contact>" in conversation list
    Then I see the conversation with <Contact> is opened
    And I see Cancel Request button on Single user Pending outgoing connection page

    Examples:
      | Name      | Contact   | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2491 @regression @landscape
  Scenario Outline: I want to verify you cannot send the invitation message twice [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact2>
    And User <Contact2> is connected to <Contact>
    And I sign in user <Name> with fast login
    And I wait until <Contact> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact>" in Search UI input field
    And I tap on conversation <Contact> in search result
    And I tap Connect button on Single user Pending outgoing connection page
    And I tap X button on Single user Pending outgoing connection page
    And I tap X button on Search UI page
    Then I see the name of the first conversation is <Contact>
    When I open search screen
    And I type "<Contact>" in Search UI input field
    And I tap on conversation <Contact> in search result
    Then I see name "<Contact>" on Single user Pending outgoing connection page

    Examples:
      | Name      | Contact   | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2796 @rc @regression @landscape
  Scenario Outline: I want to verify you can send an invitation via mail [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    When I open search screen
    And I accept alert if visible
    And I tap Send Invite button on Search UI page
    And I tap Invite Others button on Contacts UI page
    # Wait for share controls load
    And I wait for 3 seconds
    And I tap Copy Invite button on Search UI page
    And I tap Back button on Contacts UI page
    And I tap X button on Search UI page
    And I open conversation "<Contact>" in conversation list
    And I tap on text input
    And I long tap on text input
    And I tap on Paste on edit menu
    And I tap Send Message button in conversation view
    Then I see last message in the conversation view contains expected message <Link>

    Examples:
      | Name      | Contact   | Link         |
      | user1Name | user2Name | get.wire.com |

  @C2465 @rc @regression @landscape
  Scenario Outline: I want to verify possibility of disconnecting from conversation list [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Me sent connection request to <Contact1>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    When I tap Cancel Request button on Single user Pending outgoing connection page
    Then I do not see conversation <Contact1> in conversations list

    Examples:
      | Name      | Contact1  |
      | user1Name | user2Name |

  @C2466 @rc @regression @landscape
  Scenario Outline: I want to verify sending connection request after disconnecting [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Me sent connection request to <Contact1>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    When I tap Cancel Request button on Single user Pending outgoing connection page
    And I wait until <Contact1> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact1>" in Search UI input field
    And I tap on conversation <Contact1> in search result
    And I tap Connect button on Single user Pending outgoing connection page
    And I do not see Connect button on Single user Pending outgoing connection page
    And I tap X button on Single user Pending outgoing connection page
    And I tap X button on Search UI page
    Then I see the name of the first conversation is <Contact1>

    Examples:
      | Name      | Contact1  |
      | user1Name | user2Name |

  @C2467 @regression @landscape
  Scenario Outline: I want to verify possibility of disconnecting from Search UI [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Me sent connection request to <Contact1>
    And I sign in user <Name> with fast login
    And I wait until <Contact1> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact1>" in Search UI input field
    And I tap on conversation <Contact1> in search result
    And I tap Cancel Request button on Single user Pending outgoing connection page
    And I confirm conversation action
    Then I see the conversation "<Contact1>" exists in Search results

    Examples:
      | Name      | Contact1  |
      | user1Name | user2Name |

  @C2442 @rc @regression @landscape
  Scenario Outline: I want to verify ignoring a connection request from another person (People view) [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User Myself is connected to <Contact1>
    And User <Contact3> sent connection request to me
    And User <Contact1> is connected to <Contact2>,<Contact3>
    And User <Contact1> has group conversation <GroupChatName> with <Name>,<Contact2>,<Contact3>
    And I sign in user <Name> with fast login
    And I am signed in properly
    When I see Pending request link in conversations list
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I select participant <Contact3> on Group Details page
    And I tap Ignore inbox-style button on Single user Pending incoming connection profile page
    Then I do not see Pending request link in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | GroupChatName |
      | user1Name | user2Name | user3Name | user4Name | IGNORECONNECT |

  @C2513 @rc @regression @landscape
  Scenario Outline: I want to verify inbox is highlighted and opened in the list [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User Myself is connected to <Contact3>
    And User <Contact> sent connection request to Me
    And User <Contact2> sent connection request to Me
    And I sign in user <Name> with fast login
    And I am signed in properly
    When I tap Incoming Pending Requests item in conversations list
    Then I see Connect button on Connection Inbox page

    Examples:
      | Name      | Contact   | Contact2  | Contact3  |
      | user1Name | user2Name | user3Name | user4Name |

  @C2431 @regression @landscape
  Scenario Outline: I want to verify displaying first and last names for the incoming connection request [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User <Contact> sent connection request to Me
    And User <Contact> changes name to <NewName>
    And I sign in user <Name> with fast login
    When I tap Incoming Pending Requests item in conversations list
    Then I see Connect button on Connection Inbox page
    And I see name "<NewName>" on Connection Inbox page

    Examples:
      | Name      | Contact   | NewName  |
      | user1Name | user2Name | New Name |

  @C2469 @regression @landscape
  Scenario Outline: I want to verify connection request is deleted from the inbox of the addresser [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact2>
    And User <Contact> sent connection request to Me
    And I sign in user <Name> with fast login
    And I am signed in properly
    When I see Pending request link in conversations list
    And User <Contact> cancels all outgoing connection requests
    Then I do not see Pending request link in conversations list

    Examples:
      | Name      | Contact   | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2436 @regression @rc @landscape
  Scenario Outline: I want to verify accepting a connection request from another person (People view) [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User <Contact1> is connected to <Contact2>,Me
    And User <Contact1> has group conversation <GroupChatName> with <Contact2>,Me
    And User <Contact2> sent connection request to Me
    And I sign in user <Name> with fast login
    When I see Pending request link in conversations list
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I select participant <Contact2> on Group Details page
    And I tap Connect inbox-style button on Single user Pending incoming connection profile page
    And I tap Back button on Single user Pending incoming connection profile page
    And I tap X button on Group Details page
    Then I see conversation <Contact2> in conversations list
    And I do not see Pending request link in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | TESTCHAT      |

  @C2470 @regression @landscape
  Scenario Outline: I want to verify copying invitation to the clipboard [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open search screen
    And I accept alert if visible
    When I tap Send Invite button on Search UI page
    And I tap Invite Others button on Contacts UI page
    # Wait for share controls load
    And I wait for 3 seconds
    And I tap Copy Invite button on Search UI page
    And I tap Back button on Contacts UI page
    And I tap X button on Search UI page
    And I open conversation "<Contact>" in conversation list
    And I tap on text input
    And I long tap on text input
    And I tap on Paste on edit menu
    And I tap Send Message button in conversation view
    Then I see link preview container in the conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |
