Feature: Direct Replies

  @C735793 @rc @regression @directreplies @landscape
  Scenario Outline: I want to reply to a picture [LANDSCAPE]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>, <Member2> in team <TeamName>
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And User <TeamOwner> sends 1 image file <Picture> to conversation <GroupConversationName>
    And I open conversation "<GroupConversationName>" in conversation list
    # Wait for the picture to be loaded
    And I wait for <SyncTimeout> seconds
    And I long tap on image in conversation view
    When I tap on Reply on edit menu
    Then I see that I'm replying to an Image message
    When I type the "<Message>" message and send it
    Then I see reply to quoted Image in conversation view

    Examples:
      | TeamOwner | TeamName | Member1   | Member2   | GroupConversationName | Picture     | Message              | SyncTimeout |
      | user1Name | Hooves   | user2Name | user3name | QA Wonderland         | testing.jpg | What a nice picture! | 3           |

  @C735794 @regression @directreplies @landscape
  Scenario Outline: I want to reply to a reply and see only one quote [LANDSCAPE]
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User adds the following device: {"<Member2>": [{"name" : "<DeviceName>"}]}
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>, <Member2> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And User <TeamOwner> sends 1 "<Original>" message to conversation <GroupConversationName>
    And I open conversation "<GroupConversationName>" in conversation list
    And User <Member2> sends message "<Reply1>" as reply to the last message of conversation <GroupConversationName>
    When I long tap "<Reply1>" message in conversation view
    And I tap on Reply on edit menu
    And I type the "<Reply2>" message and send it
    And I tap Hide keyboard button
    Then I see 2 replies in the conversation view
    And I see the last message in conversation view contains a reply
    And I see the quoted message contains text "<Reply1>"

    Examples:
      | TeamOwner | TeamName      | Member1   | Member2   | GroupConversationName | Original | Reply1 | Reply2             | DeviceName |
      | user1Name | Space Odyssey | user2Name | user3Name | Moon bus              | No way!  | Yes!   | You're kidding me! | Device1    |
