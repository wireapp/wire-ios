Feature: Exchange Messages

  @TC-4892 @TC-4896 @col1
  Scenario Outline: I want to send and receive messages in 1:1
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName>"}]}
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    And I open conversation "<Member1>" in conversation list
    When I type the default message
    And I tap on text input
    And I tap Send Message button in conversation view
    Then I see 1 default message in the conversation view
    When User <Member1> sends delivery confirmation for the recent message in Myself conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    When User <Member1> sends 1 image file <Picture> to conversation Myself
    And I wait for 5 seconds
    Then I see 1 photo in the conversation view
    # TC-4896 - I want to receive messages in 1:1 when the app is in background
    When I minimize Wire
    And User <Member1> sends 1 "<Message>" messages to conversation Myself
    And I wait for 3 seconds
    And I restore Wire
    And I perform successful Touch ID
    Then I see last message in the conversation view is expected message <Message>

    Examples:
      | TeamOwner | TeamName              | Member1   | DeviceName | DeliveredLabel | Picture     | Message |
      | user1Name |The Classified Domain  | user2Name | device1    | Delivered      | testing.jpg | Hi      |

  @TC-4893 @TC-4897 @col1
  Scenario Outline: I want to send and receive messages in a classified group conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner1> adds users <Member2> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner1> adds the following 2FA devices: {"<Member2>": [{"name": "<DeviceName>"}]}
    And User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    And User <TeamOwner> is connected to <Member2>,<TeamOwner1>
    And User <TeamOwner> has conversation <GroupChat> with <TeamOwner1>,<Member1>,<Member2> in team <TeamName>
    And I open conversation "<GroupChat>" in conversation list
    And I see classified domain label in the conversation
    When I type the default message
    And I tap Send Message button in conversation view
    Then I see 1 default messages in the conversation view
    When User <Member2> marks the recent message as read in conversation <GroupChat> via device <DeviceName>
    Then I see that recent message is seen by 1 person
    When User <Member2> sends 1 image file <Picture> to conversation <GroupChat>
    And I wait for 5 seconds
    Then I see 1 photo in the conversation view
    # TC-4897 - I want to receive messages in classified group conversations when the app is in background
    When I minimize Wire
    And User <Member2> sends 1 "<Message>" messages to conversation <GroupChat>
    And I wait for 3 seconds
    And I restore Wire
    And I perform successful Touch ID
    Then I see last message in the conversation view is expected message <Message>

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName     | TeamOwner1 | GroupChat      | DeviceName | Picture     | Message   |
      | user1Name | user2Name | user3Name | Stinky Pinky | user4Name  | FederatedGroup | device1    | testing.jpg | Hi        |

  @C1288907 @C1288917 @C1288916 @unstable
  Scenario Outline: I want to send and receive messages in unclassified group conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<TeamOwner1>" with team "<TeamName>" on column-3 backend
    And User <TeamOwner1> adds users <Member2> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner1> adds the following 2FA devices: {"<Member2>": [{"name": "<DeviceName>"}]}
    And Users of team owned by <TeamOwner1> adds the following 2FA devices: {"<TeamOwner1>": [{"name": "<DeviceName1>"}]}
    And User <TeamOwner> is connected to <TeamOwner1>,<Member2>
    And User <TeamOwner> has conversation <GroupChat> with <TeamOwner1>,<Member1>,<Member2> in team <TeamName>
    And User <TeamOwner> is me
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<GroupChat>" in conversation list
    And I see unclassified domain label in the conversation
    When I type the default message
    And I tap Send Message button in conversation view
    Then I see 1 default messages in the conversation view
    #When User <Member2> marks the recent message as read in conversation <GroupChat> via device <DeviceName>
    #Then I see that recent message is seen by 1 person
    When User <Member2> sends 1 image file <Picture> to conversation <GroupChat>
    And I wait for 5 seconds
    Then I see 1 photo in the conversation view
    # C1288916 - I want to receive messages in unclassified group conversations when the app is in background
    When I minimize Wire
    And User <Member2> sends 1 "<Message>" messages to conversation <GroupChat>
    And I wait for 3 seconds
    And I restore Wire
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    And I do not see Encryption At Rest overlay
    Then I see last message in the conversation view is expected message <Message>
    # C1288917 - I want to send and receive messages in 1:1 with an unclassified user
    When I navigate back to conversations list
    And I open conversation "<TeamOwner1>" in conversation list
    And I type the default message
    And I tap Send Message button in conversation view
    Then I see 1 default messages in the conversation view
    When User <TeamOwner1> sends delivery confirmation for the recent message in Myself conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    When User <TeamOwner1> sends 1 image file <Picture> to conversation Myself
    And I wait for 5 seconds
    Then I see 1 photo in the conversation view

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName     | TeamOwner1 | GroupChat      | DeliveredLabel | DeviceName | DeviceName1 | Picture     | Message  |
      | user1Name | user2Name | user3Name | Stinky Pinky | user4Name  | FederatedGroup | Delivered      | device1    | device2     | testing.jpg | Hi       |

  @TC-5014 @col1
  Scenario Outline: I should not see the encryption at rest overlay on receiving a message while the app is in foreground
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <GroupChat> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName>"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member2>": [{"name": "<DeviceName1>"}]}
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    And I open conversation "<GroupChat>" in conversation list
    And I type the default message
    And I tap on text input
    And I tap Send Message button in conversation view
    And I see 1 default message in the conversation view
    When User <Member1> sends 1 "<Message>" messages to conversation <GroupChat>
    Then I do not see Encryption At Rest overlay
    When User <Member2> sends 1 "<Message>" messages to conversation <GroupChat>
    Then I do not see Encryption At Rest overlay
    When User <Member1> sends 1 "<Message1>" messages to conversation <GroupChat>
    And I wait for 3 seconds
    Then I do not see Encryption At Rest overlay
    Then I see last message in the conversation view is expected message <Message1>

    Examples:
      | TeamOwner | TeamName              | Member1   | DeviceName | DeviceName1 | Message | Member2   | GroupChat  | Message1 |
      | user1Name |The Classified Domain  | user2Name | device1    | device2     | Hi      | user3Name | Group      | Message  |