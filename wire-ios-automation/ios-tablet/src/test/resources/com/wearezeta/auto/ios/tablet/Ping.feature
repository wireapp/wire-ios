Feature: Ping

  @C2758 @regression @landscape
  Scenario Outline: I want to verify you can send Ping in a group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    When I tap Ping button from input tools
    Then I see "<PingMsg>" ping message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName        | PingMsg    |
      | user1Name | user2Name | user3Name | ReceivePingGroupChat | You pinged |

  @C2640 @regression @C3224 @landscape
  Scenario Outline: I want to verify you can see Ping on the other side - group conversation [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And User add the following device: {"<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I open group conversation "<GroupChatName>" in conversation list
    When User <Contact1> pings conversation <GroupChatName>
    Then I see "<Contact1> pinged" ping message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | GroupChatName        |
      | user1Name | user2Name | user3Name | ReceivePingGroupChat |

  @C2642 @regression @C3222 @landscape
  Scenario Outline: I want to verify you can see Ping on the other side - 1:1 conversation [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User <Contact1> change name to <ContactName>
    And User Myself is connected to <Contact1>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    And User <Contact1> pings conversation <Name>
    When I wait for 3 seconds
    Then I see "<ContactName> pinged" ping message in the conversation view

    Examples:
      | Name      | Contact1  | ContactName |
      | user1Name | user2Name | OtherUser   |

  @C2658 @regression @landscape
  Scenario Outline: I want to verify sending ping in 1-to-1 conversation LANDSCAPE
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    When I tap Ping button from input tools
    Then I see "<PingMsg>" ping message in the conversation view

    Examples:
      | Name      | Contact   | PingMsg    |
      | user1Name | user2Name | You pinged |
