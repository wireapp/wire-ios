Feature: File Transfer

  @C145955 @rc @regression @landscape
  Scenario Outline: I want to verify sending the file in an empty conversation and text after it [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    When I tap File Transfer button from input tools
    # Wait for file transfer menu
    And I wait for 5 seconds
    And I tap file transfer option for 80 MB file
    And I type the default message and send it
    Then I see file transfer placeholder

    Examples:
      | Name      | Contact   | ItemName           |
      | user1Name | user2Name | CountryCodes.plist |

  @C145956 @rc @regression @landscape
  Scenario Outline: I want to verify downloading and opening file for a preview [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I create temporary file <FileSize> in size with name "<FileName>" and extension "<FileExt>"
    And User adds the following device: {"<Contact>": [{"name" : "<ContactDevice>"}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends temporary file <FileName>.<FileExt> having MIME type <FileMIME> to single user conversation <Name> using device <ContactDevice>
    And I open conversation "<Contact>" in conversation list
    # Wait for the placeholder to be loaded
    And I wait for 3 seconds
    When I wait up to <Timeout> seconds until the file <FileName>.<FileExt> with size <FileSize> is ready for download from conversation view
    Then I tap file transfer action button until File Actions menu is visible

    Examples:
      | Name      | Contact   | FileName | FileExt | FileSize | FileMIME                 | ContactDevice | Timeout |
      | user1Name | user2Name | testing  | apk     | 240 KB   | application/octet-stream | device1       | 20      |
