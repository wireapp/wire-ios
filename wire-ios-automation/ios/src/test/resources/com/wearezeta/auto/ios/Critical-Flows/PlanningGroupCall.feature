Feature: Planning Group Calls

  # TODO: Uncomment final line when locators for images fixed
  @flows @TC-8580
  Scenario Outline: Team owner planning a group call (Audio call)
    Given I allow camera access
    And I allow access to all photos
    And I allow microphone access
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And TeamOwner "<TeamOwner>" waits and enables conference calling feature for team <TeamName> via backdoor
    And User <TeamOwner> adds user <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
    And I login to Wire as <TeamOwner>
    And I open search screen
    And I open search screen
    And I create new group "<ConversationTitle>"
    And I add members <Member1>, <Member2> to new group via search
    And User <TeamOwner> sends 1 default messages to conversation <ConversationTitle>
    And I navigate back to conversations list
    And I open conversation "<ConversationTitle>" in conversation list
    When I start a call
    And I tap on active mute button
    And I tap on inactive mute button
    When I tap Minimize button on Calling overlay
    And I type the default message and send it
    And I tap ellipsis button from input tools
    And I tap Share Location button from input tools
    And I tap Send location button from map view
    And I tap Add Picture button from input tools
    And I select the first item from Keyboard Gallery
    And I tap on OK button for the image
    #Then I see 1 photo in the conversation view

    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | ConversationTitle   |
      | user1Name | user3Name | SuperTeam | user2Name | conversation        |
