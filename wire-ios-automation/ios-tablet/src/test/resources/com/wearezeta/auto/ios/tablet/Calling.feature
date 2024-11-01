Feature: Calling

  @C2400 @C2409 @calling @landscape
  Scenario Outline: I want to start and end outgoing call by same person [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I tap Audio Call button
    And I see Calling overlay
    When I tap Leave button on Calling overlay
    Then I do not see Calling overlay

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2410 @calling @landscape
  Scenario Outline: I want to verify ignoring of incoming call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    When <Contact> calls me
    And I see call status message contains "<Contact>"
    And I tap Leave button on Calling overlay
    Then I do not see Calling overlay

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C2411 @rc @calling @landscape
  Scenario Outline: I want to verify accepting incoming call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    When <Contact> calls me
    And I see call status message contains "<Contact>"
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    Then I see call status message contains "<Contact>"

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C2399 @calling @landscape
  Scenario Outline: I want to verify receiving missed call notification from one user [LANDSCAPE] - AUDIO-1201
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    When <Contact> calls me
    And I wait for 5 seconds
    And <Contact> stops outgoing call to me
    And I open conversation "<Contact>" in conversation list
    Then I see "Missed call" system message in the conversation view

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C700181 @calling @forceReset @landscape
  Scenario Outline: I want to screenlock device when in the call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And <Contact> accepts next incoming call automatically
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I tap Audio Call button
    And I see Calling overlay
    Then I lock screen for 5 seconds
    And I see Calling overlay

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C2427 @rc @calling_advanced @landscape @knownbug
  Scenario Outline: I want to verify 3rd person tries to call me after I init a call to somebody [LANDSCAPE] - SQCALL-459
    Given There are 3 users where <Name> is me
    And User Myself is connected to all other users
    And User <Contact1> sets the unique username
    And <Contact1> starts instance using <CallBackend>
    And <Contact1> accepts next incoming call automatically
    And User <Contact2> sets the unique username
    And <Contact2> starts instance using <CallBackend2>
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact1>" in conversation list
    When I tap Audio Call button
    And I accept alert if visible
    And I see Calling overlay
    And <Contact2> calls me
    And I see call status message contains "<Contact2>"
    And I tap Leave button on Calling overlay
    And I see Calling overlay
    And <Contact2> stops outgoing call to me
    And I tap Leave button on Calling overlay
    And I do not see Calling overlay
    Then I see status of conversations list item <Contact2> is not "Missed call"
    When I open conversation "<Contact2>" in conversation list
    Then I see "Missed call" system message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | CallBackend | CallBackend2 |
      | user1Name | user2Name | user3Name | chrome      | chrome       |

  @C2395 @calling @landscape
  Scenario Outline: I want to put app into background after initiating call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I tap Audio Call button
    And I see Calling overlay
    Then I minimize Wire for 5 seconds
    And I see Calling overlay

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C700182 @calling @landscape
  Scenario Outline: I want to accept a call through the incoming voice dialogue (Button) [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And <Contact> calls me
    And I see call status message contains "<Contact>"
    And I tap Accept button on Calling overlay
    Then I see End Call button on Calling overlay

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C2401 @calling @landscape
  Scenario Outline: I want to end the call from the ongoing voice overlay [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I tap Audio Call button
    And I see Calling overlay
    And I tap Leave button on Calling overlay
    Then I do not see Calling overlay
    And <Contact> calls me
    And I see call status message contains "<Contact>"
    And I tap Accept button on Calling overlay
    And I wait for 5 seconds
    And <Contact> stops outgoing call to me
    And I do not see Calling overlay

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C2413 @rc @calling @landscape
  Scenario Outline: I want to verify putting client to the background during 1-to-1 call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    When <Contact> calls me
    And I see call status message contains "<Contact>"
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    And I see End Call button on Calling overlay
    When I minimize Wire for 5 seconds
    Then I see Calling overlay

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |

  @C145968 @rc @calling @landscape
  Scenario Outline: I want to verify starting a group call [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And Personal Users <Name> enables conference calling feature via backdoor
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I see conversations list
    Then I open group conversation "<GroupChatName>" in conversation list
    And I tap Audio Call button
    And I accept alert if visible
    And I see Calling overlay
    When I tap Leave button on Calling overlay
    Then I do not see Calling overlay

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName |
      | user1Name | user2Name | user3Name | GROUPCALL     |

  @C145969 @rc @calling_advanced @landscape
  Scenario Outline: I want to verify leaving and coming back to the call in 20 seconds [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And Personal Users <Name> enables conference calling feature via backdoor
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User <Contact1> sets the unique username
    And User <Contact2> sets the unique username
    And <Contact1>,<Contact2> starts instance using <CallBackend>
    And <Contact1>,<Contact2> accept next incoming call automatically
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    When I tap Audio Call button
    And I accept alert if visible
    # Wait for the call to be established
    And I wait for 8 seconds
    And I swipe up to see the participants list
    And I see <NumberOfAvatars> participants on the Calling overlay
    Then I tap Leave button on Calling overlay
    And I do not see Calling overlay
    When I wait for 20 seconds
    And I tap JOIN button in conversations list next to <GroupChatName>
    # Wait for the call to be established
    And I wait for 8 seconds
    And I swipe up to see the participants list
    Then I see <NumberOfAvatars> participants on the Calling overlay

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | CallBackend | NumberOfAvatars |
      | user1Name | user2Name | user3Name | GROUPCALL     | chrome      | 3               |

  @C145950 @rc @calling @landscape
  Scenario Outline: I want to verify joining 2 other people on the group call [LANDSCAPE]
    And There are 3 users where <Name> is me
    And Personal Users <Contact1> enables conference calling feature via backdoor
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User <Contact1> sets the unique username
    And User <Contact2> sets the unique username
    And <Contact1>,<Contact2> starts instance using <CallBackend>
    And <Contact2> accepts next incoming call automatically
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open group conversation "<GroupChatName>" in conversation list
    And <Contact1> calls <GroupChatName>
    Then I see call status message contains "<GroupChatName>"
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    # Wait for the call to be established
    And I wait for 5 seconds
    And I see profile picture avatar for users <Contact1>,<Contact2>,<Name> on calling overlay

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName | CallBackend |
      | user1Name | user2Name | user3Name | GROUPCALL     | chrome      |
