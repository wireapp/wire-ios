Feature: File Sending

  @flows @TC-8581
  Scenario Outline: Conversation sending and receiving a file from someone in a different team
    Given I allow camera access
    And I allow microphone access
    Given There is a team owner "<TeamOwnerA>" with team "<TeamNameA>"
    And There is a team owner "<TeamOwnerB>" with team "<TeamOwnerB>"
    And I create temporary file <FileSize> in size with name "<FileName>" and extension "<FileExt>"
    And User adds the following device: {"<TeamOwnerA>": [{"name": "Device1"}]}
    And <TeamOwnerA> starts instance using <CallBackend>
    When I login to Wire as <TeamOwnerB>
    Given User <TeamOwnerA> sent connection request to <TeamOwnerB>
    When I accept connection request from <TeamOwnerA>
    And I wait for 1 seconds
    And I type the "guten tag" message and send it
    Given User <TeamOwnerA> sends temporary file <FileName>.<FileExt> having MIME type <FileMIME> to group conversation <TeamOwnerB> using device Device1
    When I long tap on file transfer placeholder in conversation view
    And I tap on Download on edit menu
    And I wait for 2 seconds
    And I tap on file transfer placeholder in conversation view
    And I share the current file in conversation <TeamOwnerA>
    Then I see 2 file transfer placeholder in the conversation view
    When I tap Audio Message button from input tools
    And I tap Start Recording button on Voice Filters overlay
    And I wait for 2 seconds
    And I tap Stop Recording button on Voice Filters overlay
    And I tap Confirm button on Voice Filters overlay
    Then I see audio message container in the conversation view
    Then I see "Delivered" on the message toolbox in conversation view
    When I tap Play audio message button
    And I wait for 3 seconds

    Examples:
      | TeamOwnerA | TeamNameA | CallBackend | TeamOwnerB | FileSize | FileName | FileExt | FileMIME        |
      | user3Name  | SuperTeam | chrome      | user2Name  | 1204 KB  | TestFile | pdf     | application/pdf |
