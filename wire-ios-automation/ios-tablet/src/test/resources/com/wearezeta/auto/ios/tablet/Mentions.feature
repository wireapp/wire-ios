Feature: Mentions

  @C722994 @regression @mentions @landscape
  Scenario Outline: I want to be able to write a mention in a group
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I open group conversation "<ConversationName>" in conversation list
    When I tap Mention button from input tools
    And I tap <TeamOwner> in the suggested mentions list
    And I type the "<Message>" message and send it
    Then I see the last message in the conversation view contains mentions <TeamOwner>
    And I see last message in the conversation view is expected message @<TeamOwner> <Message>

    Examples:
      | TeamOwner | TeamName        | Member1   | Member2   | ConversationName | Message              |
      | user1Name | White Chocolate | user2Name | user3Name | With nougat      | No chocolate for you |

  @C722993 @regression @mentions
  Scenario Outline: I want to see a subtitle in the conversation list when there is one or more unread mentions in the conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I rotate UI to portrait
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And User <Member2> sends 1 default message to conversation <ConversationName>
    When User <TeamOwner> sends 2 messages "Hello @<Member1>" with mention to conversation Myself
    Then I see the secondary line in conversations list item <TeamOwner> is "2 mentions"

    Examples:
      | TeamOwner | TeamName        | Member1   | Member2   | ConversationName |
      | user1Name | White Chocolate | user2Name | user3Name | With nougat      |

  @C725847 @regression @mentionsnotifications @landscape
  Scenario Outline: [Teams] I want to set notification settings for group conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    When I swipe right on conversation <ConversationName> in Conversations view
    And I tap Notifications… conversation action button
    And I tap Nothing conversation action button
    Then I see status of conversations list item <ConversationName> is "Silenced"
    When I swipe right on conversation <ConversationName> in Conversations view
    And I tap Notifications… conversation action button
    And I tap Everything conversation action button
    Then I see status of conversations list item <ConversationName> is not "Silenced"
    When I swipe right on conversation <ConversationName> in Conversations view
    And I tap Notifications… conversation action button
    And I tap Mentions and Replies conversation action button
    Then I see status of conversations list item <ConversationName> is "Silenced"

    Examples:
      | TeamOwner | Member1   | Member2   | ConversationName      | TeamName                   |
      | user1Name | user2Name | user3Name | Theater Party Tonight | Intelligence and Integrity |

  @C723021 @rc @regression @mentions @landscape
  Scenario Outline: I want to see suggestions list on iPad in landscape mode
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User adds the following device: {"<TeamOwner>": [{"name": "<DeviceName>"}]}
    And There is personal account user <Guest>
    And User <TeamOwner> is connected to <Guest>
    And User <TeamOwner> has conversation <ConversationName> with <Member1>, <Guest> in team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I see conversation <ConversationName> in conversations list
    And I open conversation "<TeamOwner>" in conversation list
    And I open conversation details
    And I switch to Devices tab on Single user profile page
    And I open details page of device number 1 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap X button on Single user profile page
    And I open group conversation "<ConversationName>" in conversation list
    When I tap Mention button from input tools
    Then I see the suggested mentions list
    When I type the "<Guest>" message
    Then I see the guest icon in the suggestions list for user <Guest>
    When I clear conversation text input
    And I tap Mention button from input tools
    And I type the "<TeamOwner>" message
    Then I see the verified icon in the suggestions list for user <TeamOwner>

    Examples:
      | TeamOwner | TeamName    | Member1   | Guest     | ConversationName | DeviceName |
      | user1Name | AwesomeTeam | user2Name | user3Name | Team Convo       | M1         |