Feature: Video Calls

  @flows @TC-8586
  Scenario Outline: Team members attending stand up (Video call)
    Given I allow camera access
    And I allow microphone access
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And TeamOwner "<TeamOwner>" waits and enables conference calling feature for team <TeamName> via backdoor
    And User <TeamOwner> adds user <Member1>,<Member2>,<Member3> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
    When I login to Wire as <TeamOwner>
    And  I open search screen
    And I open create group screen
    And I create new group "<ConversationTitle>"
    And I add members <Member1>, <Member2>, <Member3> to new group via search
  # Add service to team
    When I open group conversation details
    And I add service <ServiceName> to group
    Then I see "You added <ServiceName>" system message in the conversation view
  # Team members send message and user reacts
    When User <Member1> sends 1 default messages to conversation <ConversationTitle>
    And I long tap default message in conversation view
    And I tap on ❤️ reaction in quick reactions
    Then I see ❤️ reaction in the conversation view
  # Remove person from group
    When I open group conversation details
    And I remove <Member3> from group
    And I close Group Details
    Then I see "You removed <Member3>" system message in the conversation view
  # Adding new person to team and group
    Given User <TeamOwner> adds user <Member4> to team <TeamName> with role Member
    And User adds the following device: {"<Member4>": [{"name": "Device3"}]}
    When I open group conversation details
    And I add members <Member4> to existing group via search
    Then I see "You added <Member4>" system message in the conversation view
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
  # Start video call while doing other things
    When I tap Video Call button
    And I tap Minimize button on Calling overlay
    And I type the default message and send it
    When I navigate back to conversations list
    And I open group conversation "<ConversationTitle>" in conversation list
    And I type the default message and send it
    And I tap ellipsis button from input tools
    And I tap Ping button from input tools
    When I restore Calling overlay
    And I see Video Calling overlay
    And I switch Off camera button
    And I Switch ON camera button
    When I tap Leave button on Calling overlay
    Then I do not see Calling overlay

    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | Member3   | Member4   | ConversationTitle   | ServiceName |
      | user1Name | user3Name | SuperTeam | user2Name | user3Name | user4Name | conversation        | Poll Bot    |