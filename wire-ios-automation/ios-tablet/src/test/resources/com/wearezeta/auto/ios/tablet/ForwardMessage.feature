Feature: Forward Message

  @C345391 @regression @landscape
  Scenario Outline: I want to verify forwarding own picture
    Given I allow access to all photos
    And I allow camera access
    And There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact1>" in conversation list
    And I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I select the first item from Keyboard Gallery
    And I tap Confirm button on Picture preview page
    # Wait for the picture to be loaded
    And I wait for 3 seconds
    And I long tap on image in conversation view
    When I tap on Share on edit menu
    And I select <Contact2> conversation on Forward page
    And I tap Send button on Forward page
    Then I see the conversation with <Contact1> is opened
    When I open conversation "<Contact2>" in conversation list
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  |
      | user1Name | user2Name | user3name |

  @C345394 @rc @regression @landscape
  Scenario Outline: I want to verify outgoing/incoming connection requests/ left conversations are not in a forward list
    Given There are 6 users where <Name> is me
    And User Myself is connected to <ConnectedUser1>,<ConnectedUser2>,<BlockedUser>
    And User Myself has group conversation <GroupChatName> with <ConnectedUser1>,<ConnectedUser2>
    And User Myself blocks user <BlockedUser>
    And User <NonConnectedIncomingUser> sent connection request to Me
    And User Myself sent connection request to <NonConnectedOutgoingUser>
    And User adds the following device: {"<ConnectedUser1>": [{}]}
    And User Myself changes users <ConnectedUser1> to role Admin for conversation "<GroupChatName>"
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <ConnectedUser1> removes user Me from group conversation <GroupChatName>
    And User <ConnectedUser1> sends 1 default message to conversation Myself
    And I see conversations list
    And I open conversation "<ConnectedUser1>" in conversation list
    And I long tap default message in conversation view
    When I tap on Share on edit menu
    Then I do not see <NonConnectedIncomingUser> conversation on Forward page
    And I do not see <NonConnectedOutgoingUser> conversation on Forward page
    And I do not see <GroupChatName> conversation on Forward page
    And I do not see <BlockedUser> conversation on Forward page

    Examples:
      | Name      | ConnectedUser1 | ConnectedUser2 | NonConnectedIncomingUser | NonConnectedOutgoingUser | BlockedUser | GroupChatName |
      | user1Name | user2Name      | user3name      | user4name                | user5Name                | user6Name   | Group         |

  @C345393 @rc @regression @landscape
  Scenario Outline: I want to verify message is sent as normal when ephemeral keyboard is chosen in the destination conversation
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User adds the following device: {"<Contact2>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact2> sends 1 default message to conversation Myself
    And I see conversations list
    And I open conversation "<Contact1>" in conversation list
    And I tap Hourglass button in conversation view
    And I set self deleting message expiration timer to <Timeout> seconds on conversation view
    # This is to close expiration timer popup
    And I tap at 50%,50% of the viewport size
    And I open conversation "<Contact2>" in conversation list
    And I wait for 5 seconds
    And I long tap default message in conversation view
    When I tap on Share on edit menu
    And I select <Contact1> conversation on Forward page
    And I tap Send button on Forward page
    And I open conversation "<Contact1>" in conversation list
    And I wait for <Timeout> seconds
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | Timeout |
      | user1Name | user2Name | user3name | 10      |

  @C345395 @regression @landscape
  Scenario Outline: I want to verify forwarding to archived conversation unarchive it
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And Users add the following devices: {"Myself": [{}], "<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends 1 default message to conversation Myself
    And I see conversations list
    And User Myself archives conversation <Contact2>
    And I do not see conversation <Contact2> in conversations list
    And I open conversation "<Contact1>" in conversation list
    And I long tap default message in conversation view
    When I tap on Share on edit menu
    And I select <Contact2> conversation on Forward page
    And I tap Send button on Forward page
    Then I see conversation <Contact2> in conversations list

    Examples:
      | Name      | Contact1  | Contact2  |
      | user1Name | user2Name | user3name |

  @C345388 @regression @landscape
  Scenario Outline: I want to verify forwarding own text message
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact1>" in conversation list
    And I type the default message and send it
    And I long tap default message in conversation view
    When I tap on Share on edit menu
    And I select <Contact2> conversation on Forward page
    And I tap Send button on Forward page
    Then I see the conversation with <Contact1> is opened
    When I open conversation "<Contact2>" in conversation list
    Then I see 1 default message in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  |
      | user1Name | user2Name | user3name |

  @C345392 @regression @landscape
  Scenario Outline: I want to verify forwarding someone else audio message
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And Users add the following devices: {"Myself": [{}], "<Contact1>": [{"name": "<ContactDevice>"}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends file <FileName> having MIME type <FileMIME> to single user conversation <Name> using device <ContactDevice>
    And User Me sends 1 default message to conversation <Contact1>
    And I see conversations list
    And I open conversation "<Contact1>" in conversation list
    # Small wait to make the appearence of button on jenkins more stable
    And I wait for 3 seconds
    When I long tap on audio message placeholder in conversation view
    Then I do not see Share on edit menu
    When I tap Play audio message button
    # Small wait to make sure download is completed
    And I wait for 5 seconds
    And I long tap on audio message placeholder in conversation view
    And I tap on Share on edit menu
    And I select <Contact2> conversation on Forward page
    And I tap Send button on Forward page
    Then I see the conversation with <Contact1> is opened
    When I open conversation "<Contact2>" in conversation list
    Then I see audio message container in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | FileName | FileMIME  | ContactDevice |
      | user1Name | user2Name | user3name | test.m4a | audio/mp3 | Device1       |

  @C345390 @regression @landscape
  Scenario Outline: I want to verify forwarding someone else video message
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact1>,<Contact2>
    And User adds the following device: {"<Contact1>": [{"name": "<DeviceName>"}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends file <FileName> having MIME type <MIMEType> to single user conversation <Name> using device <DeviceName>
    # Wait for delivery
    And I wait for 2 seconds
    And I open conversation "<Contact1>" in conversation list
    # Small wait to make the appearence of button on jenkins more stable
    And I wait for 6 seconds
    And I tap on video message in conversation view
      # Small wait to make sure download is completed
    And I wait for 4 seconds
    And I tap Done button on video message player page
    And I long tap on video message in conversation view
    And I tap on Share on edit menu
    And I select <Contact2> conversation on Forward page
    When I tap Send button on Forward page
    And I see the conversation with <Contact1> is opened
    And I open conversation "<Contact2>" in conversation list
    Then I see video message container in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | FileName    | MIMEType  | DeviceName |
      | user1Name | user2Name | user3name | testing.mp4 | video/mp4 | Device1    |
