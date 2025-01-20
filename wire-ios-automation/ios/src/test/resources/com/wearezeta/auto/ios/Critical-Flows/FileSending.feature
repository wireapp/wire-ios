Feature: File Sending

  @flows @02
  Scenario Outline: Person submitting a file to an employee
  # Team exists with at least 1 member
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
  # External guest has already been registered
    And There is personal account user <Guest>
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
  # A document exists
    And I create temporary file <FileSize> in size with name "<FileName>" and extension "<FileExt>"
    And User adds the following device: {"<TeamOwner>": [{"name": "Device1"}]}
    And User <TeamOwner> has conversation <ConversationTitle> with <Member1> in team <TeamName>
    And <TeamOwner> starts instance using <CallBackend>
    And User <TeamOwner> creates invite link for conversation <ConversationTitle>
    And User <Guest> is me
    And I sign in user <Guest> with fast login
    And I accept alert if visible
    And I am signed in properly
    When I minimize Wire
    And I open invite link url for conversation <ConversationTitle> created by user <TeamOwner> in safari
    And I wait for 5 seconds
    And I tap Join in the app button in Safari
    And I tap Open button on the alert
    And I tap OK button on the alert
    And I type the "guten tag" message and send it
    # Employee sends empty document to external guest
    And User <TeamOwner> sends temporary file <FileName>.<FileExt> having MIME type <FileMIME> to group conversation <ConversationTitle> using device Device1
    # Guest is able to download
    And I long tap on file transfer placeholder in conversation view
    And I tap on Download on edit menu
    And I wait for 2 seconds
    And I tap on file transfer placeholder in conversation view
    # Guest sends filled document to the employee
    And I tap Share button in file inspection page
    And I tap More button on share extension
    And I tap Wire in share extension
    And I tap Choose in share extension
    And I select conversation "<ConversationTitle>" in share extension
    And I tap Send button in share extension
    And I tap Done button in file inspection page
    Then I see 2 file transfer placeholder in the conversation view
    And I type the "Here is my version" message and send it
    # Employee is able to download the document (not implemented as other client)
    And User <TeamOwner> sends message "Yeah this is not what we need" as reply to last message of conversation <ConversationTitle> via device Device1
    And User <TeamOwner> sends 1 "let me call you to clarify" message to conversation <ConversationTitle>
      # Employee calls 1:1
    And <TeamOwner> calls <ConversationTitle>
      # Both are able to open camera
      # Employee sends a few links
      # Guest removes previous document message
      # Guest send another document during call

    Examples:
      | Member1   | TeamOwner | TeamName  | CallBackend | Guest     | ConversationTitle  | FileSize | FileName | FileExt | FileMIME        |
      | user1Name | user3Name | SuperTeam | chrome      | user2Name | Anmeldungdesk     | 1204 KB  | TestFile | pdf     | application/pdf |
