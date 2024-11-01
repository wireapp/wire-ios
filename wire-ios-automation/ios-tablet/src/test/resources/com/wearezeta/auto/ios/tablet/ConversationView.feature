Feature: Conversation View

  @C2647 @regression @landscape
  Scenario Outline: I want to send Message to contact after navigating away from chat page [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Me is connected to <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    And I type the default message
    When I open conversation "<Contact2>" in conversation list
    And I open conversation "<Contact1>" in conversation list
    And I tap on text input
    And I tap Send Message button in conversation view
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  |
      | user1Name | user2Name | user3Name |

  @C2655 @regression @landscape
  Scenario Outline: I want to copy and paste to send the message [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Contact> with fast login
    And I open conversation "<Contact>" in conversation list
    And I tap on text input
    And I load clipboard content from string "<Text>"
    When I long tap on text input
    And I tap on Paste on edit menu
    And I tap Send Message button in conversation view
    Then I see last message in the conversation view is expected message <Text>

    Examples:
      | Name      | Contact   | Text       |
      | user1Name | user2Name | TextToCopy |

  @C2677 @regression @landscape
  Scenario Outline: I can send a sketch [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact1>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    When I tap Sketch button from input tools
    And I draw a random sketch
    And I tap Send button on Sketch page
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact1  |
      | user1Name | user2Name |

  @C2598 @regression @landscape
  Scenario Outline: I want to tap the cursor to get to the end of the conversation [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 19 default messages to conversation Myself
    When I open conversation "<Contact>" in conversation list
    Then I see conversation is scrolled to the end

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2662 @unstable @landscape
  Scenario Outline: I can send and play inline youtube link [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    And I type the "<YouTubeLink>" message and send it
    And I tap Hide keyboard button
    When I tap on Youtube preview in conversation view
    And I wait for 5 seconds
    Then I see the video player web page is opened

    Examples:
      | Name      | Contact   | YouTubeLink                                |
      | user1Name | user2Name | http://www.youtube.com/watch?v=Bb1RhktcugU |

  @C2601 @regression @landscape
  Scenario Outline: I want to verify only people icon exists under the plus in pending/left/removed from conversations [LANDSCAPE]
    Given There are 4 users where <Name> is me
    And User Myself is connected to <Contact2>,<Contact3>
    And User Myself has group conversation <GroupChatName> with <Contact2>,<Contact3>
    And User Me sent connection request to <Contact1>
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself leaves group chat <GroupChatName>
    When I open conversation "<Contact1>" in conversation list
    Then I do not see conversation tools buttons
    When I open archived conversations
    And I open group conversation "<GroupChatName>" in conversation list
    Then I do not see conversation tools buttons

    Examples:
      | Name      | Contact1  | Contact2  | Contact3  | GroupChatName    |
      | user1Name | user2Name | user3Name | user4Name | ArchiveGroupChat |

  @C2549 @regression @landscape
  Scenario Outline: I want to verify posting in a 1-to-1 conversation without content [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact1>
    And User adds the following device: {"Myself": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User Myself sends 1 default message to conversation <Contact1>
    When I swipe right on conversation <Contact1> in Conversations view
    And I tap Clear Content… conversation action button
    And I tap Clear conversation action button
    Then I do not see conversation <Contact1> in conversations list
    When I wait until <Contact1> exists in backend search results
    When I open search screen
    And I accept alert if visible
    And I type "<Contact1>" in Search UI input field
    And I tap on conversation <Contact1> in search result
    When I type the default message and send it
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact1  |
      | user1Name | user2Name |

  @C2592 @regression @landscape
  Scenario Outline: I want to verify cursor tooltip is shown
    Given There are 2 user where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    When I open conversation "<Contact>" in conversation list
    Then I see TYPE A MESSAGE input placeholder text
    When I tap on text input
    Then I see TYPE A MESSAGE input placeholder text
    When I type the default message
    Then I do not see TYPE A MESSAGE input placeholder text
    When I tap Send Message button in conversation view
    Then I see TYPE A MESSAGE input placeholder text

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |