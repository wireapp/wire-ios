Feature: Audio Messaging

  @C145953 @rc @unstable @landscape @flaky
  Scenario Outline: I want to verify recording and sending an audio message [LANDSCAPE] BUG: flaky on Nightly runs
    Given There are 2 user where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    #audio message nr.1 is short tap a and is needed to accept permission
    When I tap Audio Message button from input tools
    And I accept alert if visible
    And I tap Start Recording button on Voice Filters overlay
    And I wait for 5 seconds
    And I tap Stop Recording button on Voice Filters overlay
    And I tap Confirm button on Voice Filters overlay
    And I wait for 2 seconds
    Then I see audio message container in the conversation view
    #audio message nr.2 is long tap
    When I long tap Audio Message button for <Duration> seconds from input tools
    And I wait for <Duration> seconds
    And I tap Send record control button
    #Wait until the message is uploaded
    And I wait for 2 seconds
    Then I see audio message container in the conversation view
    When I tap Play audio message button
    Then I see state of button on audio message placeholder is Pause

    Examples:
      | Name      | Contact   | Duration |
      | user1Name | user2Name | 5        |

  @C145954 @rc @regression @landscape
  Scenario Outline: I want to verify receiving and playing an audio message [LANDSCAPE]
    Given There are 2 user where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{"name": "<ContactDevice>"}]}
    And I sign in user <Name> with fast login
    And I see conversations list
    When User <Contact> sends file <FileName> having MIME type <FileMIME> to single user conversation <Name> using device <ContactDevice>
    And I open conversation "<Contact>" in conversation list
    And User <Contact> sends 1 default message to conversation Myself
    # Wait until the media is loaded
    And I wait for 5 seconds
    And I see state of button on audio message placeholder is Play
    And I tap Play audio message button
    #This step waits until state is changed, no need for download sleep anymore
    Then I see state of button on audio message placeholder is Pause

    Examples:
      | Name      | Contact   | FileName | FileMIME  | ContactDevice |
      | user1Name | user2Name | test.m4a | audio/mp4 | Device1       |

