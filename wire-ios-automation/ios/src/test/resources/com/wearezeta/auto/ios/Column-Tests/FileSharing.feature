Feature: File sharing

  @TC-4978 @SF.IOS-VSNFDAREA @TSFI.UserInterface @S0.1 @col1 @BundSecurity
  Scenario Outline: I want to verify that file sharing is disabled on build time with FILE_SHARING_ENABLED=0
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User <TeamOwner> disables File Sharing for team <TeamName>
    And All other versions of Wire are uninstalled
    And I login to the default email verified backend as <Member1>
    And I am signed in properly
    When I open conversation "<TeamOwner>" in conversation list
    Then I do not see Add Picture button in input tools palette
    And I do not see Sketch button in input tools palette
    And I do not see Giphy button in input tools palette
    And I do not see Audio Message button in input tools palette
    And I do not see File Transfer button in input tools palette
    And I do not see Video Message button in input tools palette
    # Disbale share extension
    When I open Safari with url "<URL>"
    And I tap Share button in Safari
    And I tap Wire Bund in share extension
    And I wait for 3 seconds
    And I tap Choose in share extension
    And I wait for 3 seconds
    And I perform successful Touch ID
    And I select conversation "<TeamOwner>" in share extension
    And I tap Send button in share extension
    Then I see alert contains text "File sharing restrictions"
    And I see alert contains text "You can not share this file because this feature is disabled."

    Examples:
      | Member1   | TeamOwner | TeamName     | DeviceName | URL                        |
      | user1Name | user2Name | File sharing | device1    | https://www.duckduckgo.com |

  @C1151068 @C1151069 @C1151071 @C1151097 @C1151102 @col1filesharing @real
  Scenario Outline: I want to see the option to record a video from within the app
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"},{}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<TeamOwner>" in conversation list
    Then I see Video Message button in input tools palette
    # I want to send a video using the option to record a video from within the app - C1151069
    When I tap Video Message button from input tools
    And I accept alert if visible
    And I accept alert if visible
    And I tap Take Video button on Camera page
    And I wait for 5 seconds
    And I tap Take Video button on Camera page
    And I tap Use Video button on Camera page
    And I wait for 5 seconds
    And I accept alert if visible
    Then I see video message container in the conversation view
    When I wait for 8 seconds
    And User <TeamOwner> sends delivery confirmation for the recent message in Myself conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    When I long tap on video message in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I see Share on edit menu
    And I do not see Copy on edit menu
    # I want to forward the recorded video to another user in 1:1 - C1151071
    When I tap on Share on edit menu
    And I wait for 2 seconds
    And I select <Member2> conversation on Forward page
    And I tap Send button on Forward page
    And I navigate back to conversations list
    And I open conversation "<Member2>" in conversation list
    Then I see 1 video files in the conversation view
    And User <Member2> sends delivery confirmation for the recent message in Myself conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    # I want to forward the recorded video to another user in group - C1151072
    When I long tap on video message in conversation view
    And I tap on Share on edit menu
    And I wait for 2 seconds
    And I select <GroupConversationName> conversation on Forward page
    And I tap Send button on Forward page
    And I navigate back to conversations list
    And I open conversation "<GroupConversationName>" in conversation list
    Then I see 1 video files in the conversation view
    When User <TeamOwner> sends delivery confirmation for the recent message in <GroupConversationName> conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    # I should not be able to download the received videos - C1151097
    When User <TeamOwner> sends 1 video file <VideoFileName> to conversation <GroupConversationName>
    Then I see 1 video files in the conversation view
    When I long tap on video message in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I see Share on edit menu
    And I do not see Copy on edit menu
    # I want to receive and open video file within the app - C1151102
    When I tap on video message in conversation view
    And I wait for 2 seconds
    Then I see pause button on Video page

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName     | DeviceName | DeliveredLabel | GroupConversationName | VideoFileName |
      | user1Name | user2Name | user3Name | File sharing | device1    | Delivered      | FileSharing           | testing.mp4   |

  @TC-4958 @TC-4959 @TC-4974 @TC-4966 @TC-4961 @col1filesharing @col1
  Scenario Outline: I want to see the option to record a voice recordings from within the app
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}, {"name": "<ContactDevice>"}], "<Member1>": [{"name": "<ContactDevice1>"}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And I allow microphone access
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <Member1>
    Then I am signed in properly
    When I open conversation "<TeamOwner>" in conversation list
    Then I see Audio Message button in input tools palette
    # I want to send a voice recordings using the option to record a voice from within the app - TC-4959
    When I tap Audio Message button from input tools
    And I tap Audio Message button from input tools
    And I long tap Audio Message button from input tools
    And I tap Send record control button
    Then I see audio message container in the conversation view
    When I wait for 3 seconds
    When User <TeamOwner> sends delivery confirmation for the recent message in Myself conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    When I tap Play audio message button
    And I wait for 3 seconds
    And I long tap on audio message placeholder in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I do not see Share on edit menu
    And I do not see Copy on edit menu
    And I tap on Cancel on edit menu
    # I should not be able to download the received audios - TC-4974
    When User <TeamOwner> sends file <FileName> having MIME type <FileMIME> to single user conversation <Member1> using device <ContactDevice>
    Then I see audio message container in the conversation view
    When I long tap on audio message placeholder in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I do not see Copy on edit menu
    And I tap on Cancel on edit menu
    When I tap Play audio message button
    And I wait for 2 seconds
    And I long tap on audio message placeholder in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I do not see Share on edit menu
    And I do not see Copy on edit menu
    And I tap on Cancel on edit menu
    # I want to receive and open voice recordings within the app - TC-4966
    When I tap Play audio message button
    Then I see state of button on audio message placeholder is Play

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName     | DeviceName | DeliveredLabel | GroupConversationName | FileName | FileMIME  | ContactDevice | ContactDevice1 |
      | user1Name | user2Name | user3Name | File sharing | device1    | Delivered      | FileSharing           | test.m4a | audio/mp3 | Device1       | Device2        |

  @TC-4971 @filesharing @services @col1
  Scenario Outline: I want to see an alert on receiving a file when the team settings is OFF
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}], "<Member1>": [{"name": "<DeviceName1>"}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <Member1>
    Then I am signed in properly
    Given I create temporary file <FileSize> in size with name "<FileName>" and extension "<FileExt>"
    When I open conversation "<TeamOwner>" in conversation list
    And User <TeamOwner> disables File Sharing for team <TeamName>
    Then I see alert contains text "Team settings changed"
    And I see alert contains text "Sharing and receiving files of any type is now disabled."
    When I tap OK button on the alert
    Then I do not see Add Picture button in input tools palette
    And I do not see Sketch button in input tools palette
    And I do not see Giphy button in input tools palette
    And I do not see Audio Message button in input tools palette
    And I do not see File Transfer button in input tools palette
    And I do not see Video Message button in input tools palette
    But I see Ping button in input tools palette
    And I see Mention button in input tools palette

    Examples:
      | Member1   | TeamOwner | TeamName     | DeviceName | FileName | FileExt  | FileSize | DeviceName1 |
      | user1Name | user2Name | File sharing | device1    | TestFile |  pdf     | 1204 KB  | device2     |