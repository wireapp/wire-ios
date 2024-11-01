Feature: Teams

  @C2538 @unstable @landscape
  Scenario Outline: I want to verify the status and count of the messages in conversation list [LANDSCAPE]
    Given There are 3 users where <Name> is me
    And User Myself is connected to <Contact>, <Contact2>
    And User adds the following device: {"<Contact>": [{"name": "<ContactDevice>"}]}
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I create temporary file <FileSize> in size with name "<FileName>" and extension "<FileExt>"
    And I sign in user <Name> with fast login
    And I open conversation "<Contact2>" in conversation list
    When User <Contact> sends 1 "<Msg>" message to conversation Myself
    And I see status of conversations list item <Contact> is "1"
    Then I see the secondary line in conversations list item <Contact> is "<Msg>"
    When User <Contact> sends 1 "<Msg2>" message to conversation Myself
    Then I see the secondary line in conversations list item <Contact> is "<Msg2>"
    When User <Contact> sends 1 image file <Picture> to conversation Myself
    Then I see the secondary line in conversations list item <Contact> is "Shared a picture"
    When User <Contact> sends 1 "<Link>" message to conversation Myself
    # Wait necessary for loading link preview, otherwise subtitle is the link itself
    And I wait for 1 second
    Then I see the secondary line in conversations list item <Contact> is "Shared a link"
    When User <Contact> shares the default location to user Myself via device <ContactDevice>
    Then I see the secondary line in conversations list item <Contact> is "Shared a location"
    When User <Contact> sends temporary file <FileName>.<FileExt> having MIME type <FileMIME> to single user conversation <Name> using device <ContactDevice>
    And I see status of conversations list item <Contact> is "6"
    Then I see the secondary line in conversations list item <Contact> is "Shared a file"
    When User <Contact> pings conversation <Name>
    And I see status of conversations list item <Contact> is "ping"
    Then I see the secondary line in conversations list item <Contact> is "Pinged"
    When <Contact> calls me
    And <Contact> stops outgoing call to me
    # Wait for stability
    And I wait for 1 second
    And I see status of conversations list item <Contact> is "Missed call"
    Then I see the secondary line in conversations list item <Contact> is "Missed call"
    When User <Contact> sends 1 "<Msg>" message to conversation Myself
    And I see status of conversations list item <Contact> is "9"
    Then I see the secondary line in conversations list item <Contact> is "<Msg>"

    Examples:
      | Name      | Contact   | Contact2  | Msg   | Msg2        | Picture     | Link                | CallBackend | FileExt | FileMIME                 | FileName | ContactDevice | FileSize |
      | user1Name | user2Name | user3Name | Hello | Who are you | testing.jpg | http://www.wire.com | chrome      | bin     | application/octet-stream | testing  | device1       | 240 KB   |
