Feature: Groups

  @flows @WPB6540 @TC-8579
  Scenario Outline: Team owner making an all team chat (contains bug)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1>,<Member2>,<Member3> to team <TeamName> with role Member
    And User <TeamOwner> enables <ServiceName> service for team <TeamName>
    And User <TeamOwner> is me
    And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
    And I tap Login button on Welcome page
    And I sign in user <TeamOwner> with email
    And I accept First Time overlay
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
  # Add service to team
    When I open group conversation details
    And I tap Add People button on Group Details page
    And I tap Services tab on Team Search UI page
    And I type first 3 letters of name "<ServiceName>" in search input field on Add People page
    And I tap on service "<ServiceName>" in service search result
    And I tap Add Service button on service detail page
    When I tap X button on Group Details page
    Then I see "You added <ServiceName>" system message in the conversation view
  # Team members send message and user reacts
    When User <Member1> sends 1 default messages to conversation <ConversationTitle>
    And I long tap default message in conversation view
    And I tap on ❤️ reaction in quick reactions
    Then I see ❤️ reaction in the conversation view
  # Remove person from group
    When I open group conversation details
    And I select participant <Member3> on Group Details page
    And I tap Remove From Conversation button on Group participant profile page
    And I confirm removal from group
    And I tap X button on Group Details page
    Then I see "You removed <Member3>" system message in the conversation view
  # Adding new person to team and group
    And User <TeamOwner> adds user <Member4> to team <TeamName> with role Member
    And User adds the following device: {"<Member4>": [{"name": "Device3"}]}
    And I open group conversation details
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
    Then I see last message in the conversation view is expected message <ThankYouMessage>
    And I see 1 reply in the conversation view

    Examples:
      | Member1   | TeamOwner | TeamName  | ThankYouMessage           | ServiceName | Member2   | ConversationTitle | Member3   | Member4   | Message                         |
      | user1Name | user3Name | SuperTeam | Thank you! Hello everyone | Poll Bot    | user2Name | Official          | user4Name | user5Name | Welcome to our new team member  |
