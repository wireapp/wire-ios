Feature: Video Messaging

  @C751331 @regression @landscape
  Scenario Outline: I want to verify receiving and playing a video message [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And Users add the following devices: {"<Contact>": [{"name": "<DeviceName>"}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends file <FileName> having MIME type <MIMEType> to single user conversation <Name> using device <DeviceName>
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    When I tap on video message in conversation view
    And I wait for 2 seconds
    Then I see pause button on Video page

    Examples:
      | Name      | Contact   | FileName    | MIMEType  | DeviceName |
      | user1Name | user2Name | testing.mp4 | video/mp4 | Device1    |

  @C145951 @unstable @landscape
  Scenario Outline: I want to verify recording a video message [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I prepare <FileName> to be uploaded as a video message
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    When I tap Video Message button from input tools
    And I wait for 3 seconds
    Then I see video message container in the conversation view

    Examples:
      | Name      | Contact   | FileName    |
      | user1Name | user2Name | testing.mp4 |
