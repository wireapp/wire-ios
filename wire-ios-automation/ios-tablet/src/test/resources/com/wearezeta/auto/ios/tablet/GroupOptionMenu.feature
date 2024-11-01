Feature: Group Option Menu

  @C2744 @rc @regression @regression @landscape
  Scenario Outline: I want to leave group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Leave Group… conversation action button
    And I tap Leave conversation action button
    And I open archived conversations
    And I open group conversation "<GroupChatName>" in conversation list
    Then I see "You left" system message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | LeaveGroup    |

  @C2747 @rc @regression @landscape
  Scenario Outline: I want to unsilence the conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself removes their avatar picture
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User adds the following device: {"Myself": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself mutes conversation <GroupChatName>
    When I see status of conversations list item <GroupChatName> is "Silenced"
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    And I tap Unmute conversation action button
    Then I see status of conversations list item <GroupChatName> is not "Silenced"

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | SILENCE       |

  @C2748 @rc @regression @landscape
  Scenario Outline: I want to silence the conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself removes their avatar picture
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I see status of conversations list item <GroupChatName> is not "Silenced"
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Mute conversation action button
    And I tap X button on Group Details page
    Then I see status of conversations list item <GroupChatName> is "Silenced"

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | SILENCE       |

  @C2458 @regression @landscape
  Scenario Outline: I want to block a person from profile view [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    And I open conversation details
    And I tap Open Menu button on Single user profile page
    When I tap Block… conversation action button
    And I tap Block conversation action button
    Then I do not see conversation <Contact1> in conversations list
    And I see conversation <Contact2> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2459 @regression @landscape
  Scenario Outline: I want to unblock someone from a group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User <Name> blocks user <Contact1>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I select participant <Contact1> on Group Details page
    And I tap Open Menu button on Single user profile page
    When I tap Unblock conversation action button
    Then I see conversation <Contact1> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName    |
      | user1Name | user2Name | user3Name | UnblockFromGroup |

  @C2739 @rc @regression @landscape
  Scenario Outline: I want to verify that deleted conversation via participant view is not going to archive [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And Users add the following devices: {"Myself": [{}], "<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends 1 default message to conversation <GroupChatName>
    And User Myself sends 1 default message to conversation <GroupChatName>
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Clear Content… conversation action button
    And I tap Clear conversation action button
    Then I do not see conversation <GroupChatName> in conversations list
    And I do not see Archive button at the bottom of conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | ForDeletion   |

  @C2741 @rc @regression @landscape
  Scenario Outline: I want to verify removing the content and leaving from the group conversation via participant view [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User adds the following device: {"Myself": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself sends 1 default message to conversation <GroupChatName>
    # Wait for message delivery
    And I wait for 3 seconds
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Clear Content… conversation action button
    And I tap Clear and leave conversation action button
    And I open search UI
    And I accept alert if visible
    And I type "<GroupChatName>" in Search UI input field
    Then I see the conversation "<GroupChatName>" does not exist in Search results
    When I tap X button on Search UI page
    Then I do not see conversation <GroupChatName> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | ForDeletion   |

  @C1834 @regression @landscape
  Scenario Outline: I want to verify removing the content from the group conversation via participant view [LANDSCAPE] - ZIOS-6809
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And Users add the following devices: {"Myself": [{}], "<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself pings conversation <GroupChatName>
    And User Myself sends 1 default message to conversation <GroupChatName>
    And User <Contact1> sends 1 default message to conversation <GroupChatName>
    And User Myself sends 1 image file <Image> to conversation <GroupChatName>
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Clear Content… conversation action button
    And I tap Clear conversation action button
    When I open search screen
    And I accept alert if visible
    And I type "<GroupChatName>" in Search UI input field
    When I tap on conversation <GroupChatName> in search result
    Then I see conversation view page
    # TODO: There should be a system message there
    And I see 0 conversation entries

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | Image       |
      | user1Name | user2Name | user3Name | ForDeletion   | testing.jpg |

  @C1836 @regression @landscape
  Scenario Outline: I want to verify removing the content from 1-to-1 via participant view [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And Users add the following devices: {"Myself": [{}], "<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself pings conversation <Contact1>
    And User Myself sends 1 default message to conversation <Contact1>
    And User <Contact1> sends 1 default message to conversation Myself
    And User <Contact1> sends 1 image file <Image> to conversation Myself
    And I open conversation "<Contact1>" in conversation list
    And I open conversation details
    And I tap Open Menu button on Single user profile page
    When I tap Clear Content… conversation action button
    And I tap Clear conversation action button
    And I open search UI
    And I accept alert if visible
    And I type "<Contact1>" in Search UI input field
    And I tap on conversation <Contact1> in search result
    Then I see 0 default messages in the conversation view
    And I see 0 photos in the conversation view

    Examples:
      | Name      | Contact1  | Image       |
      | user1Name | user2Name | testing.jpg |

  @C2557 @regression @landscape
  Scenario Outline: I want to verify that left conversation is shown in the Archive [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User <Name> has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And Users add the following devices: {"Myself": [{}], "<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself sends 1 default message to conversation <GroupChatName>
    And User <Contact1> sends 1 image file <Image> to conversation <GroupChatName>
    And I open group conversation "<GroupChatName>" in conversation list
    And I open group conversation details
    And I tap Open Menu button on Group Details page
    When I tap Leave Group… conversation action button
    And I tap Leave conversation action button
    And I open archived conversations
    And I see conversation <GroupChatName> in conversations list
    And I open group conversation "<GroupChatName>" in conversation list
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | Image       |
      | user1Name | user2Name | user3Name | TESTCHAT      | testing.jpg |

  @C2737 @regression @landscape
  Scenario Outline: I want to verify canceling blocking person from participant list [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to all other users
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    And I open conversation details
    And I tap Open Menu button on Single user profile page
    When I tap Block… conversation action button
    And I dismiss popover on iPad
    And I tap X button on Single user profile page
    Then I see conversation <Contact1> in conversations list

    Examples:
      | Name      | Contact1  |
      | user1Name | user2Name |
