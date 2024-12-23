Feature: Groups

  @flows @WPB6540 @TC-8579
  Scenario Outline: Team owner making an all team chat (contains bug)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2>,<Member3> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
    And I sign in user <TeamOwner> with email
    And  I open search screen
    And I open create group screen
    And I switch Allow Guests toggle on New Group page
    And I enter group name "<ConversationTitle>" on New Group page
    And I tap Next button on New Group page
    And I type first 3 letters of name "<Member1>" in search input field on Add People page
    And I select search result item <Member1> on Add People page
    And I type first 3 letters of name "<Member2>" in search input field on Add People page
    And I select search result item <Member2> on Add People page
    And I type first 3 letters of name "<Member3>" in search input field on Add People page
    And I select search result item <Member3> on Add People page
    And I tap Create button on Add People page
  # Adding new person to team and group
    And User <TeamOwner> adds user <Member4> to team <TeamName> with role Member
    And User adds the following device: {"<Member4>": [{"name": "Device3"}]}
    And I open group conversation details
    And I see Add People button on Group Details page
    When I tap Add People button on Group Details page
    And I type search query "<Member4>" on Group Add People page
    And I select search result item <Member4> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I tap X button on Group Details page
    And I see "You added <Member4>" system message in the conversation view
# Team owner sends welcome message with mention
    When I type the "<Message>" message
    When I tap Mention button from input tools
    And I type first 2 letters of name "<Member4>" in conversation input
    And I tap <Member4> in the suggested mentions list
    And I tap Send Message button in conversation view
    Then I see last message in the conversation view contains expected message <Message>
# New member responds
    And User <Member4> sends message "<ThankYouMessage>" as reply to last message of conversation <ConversationTitle> via device Device3
    And I see last message in the conversation view is expected message <ThankYouMessage>
    And I see 1 reply in the conversation view

    Examples:
      | Member1   | TeamOwner | TeamName  | ThankYouMessage           | Member2   | ConversationTitle | Member3   | Member4   | Message                         |
      | user1Name | user3Name | SuperTeam | Thank you! Hello everyone | user2Name | Official          | user4Name | user5Name | Welcome to our new team member  |
