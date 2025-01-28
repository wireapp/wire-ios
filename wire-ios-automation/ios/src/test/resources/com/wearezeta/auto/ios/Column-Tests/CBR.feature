Feature: CBR

  @TC-4890 @col1 @cbr @SF.Calls @TSFI.RESTfulAPI @TSFI.Callkit @S0.4 @S3 @S4 @S5 @Security
  Scenario Outline: I want to verify that CBR traffic after calling 1:1 audio and video call using chrome
    Given I allow microphone access
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    And <Member1> starts 2FA instance using <CallBackend>
    And <Member1> accepts next incoming call automatically
    And I enroll the simulator for Touch ID
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<Member1>" in conversation list
    When I tap Audio Call button
    And <Member1> verifies that waiting instance status is changed to active in 20 seconds
    And User <Member1> verifies to have CBR connection
    And I wait for 7 seconds
    Then I see call indicator CONSTANT BIT RATE
    When User <Member1> switches video on
    And User <Member1> verifies to have CBR connection
    And I wait for 5 seconds
    And I tap on screen to enable video calling overlay
    Then I see label call indicator CONSTANT BIT RATE
    And I see call indicator CONSTANT BIT RATE

    Examples:
      | TeamOwner | Member1   | CallBackend | TeamName      |
      | user1Name | user2Name | chrome      | WeLikeCalling |

  @TC-4888 @col1 @cbr @SF.Calls @TSFI.RESTfulAPI @TSFI.Callkit @S0.4 @S3 @S4 @S5 @Security
  Scenario Outline: I want to verify that CBR traffic after receiving 1:1 audio and video call using chrome
    Given I allow microphone access
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> has 1:1 conversation with <Member1> in team <TeamName>
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    And I enroll the simulator for Touch ID
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    And I open conversation "<Member1>" in conversation list
    And <Member1> starts 2FA instance using <CallBackend>
    When <Member1> calls me
    And I tap Accept button on Calling overlay
    And <Member1> verifies that call status to me is changed to active in 20 seconds
    And User <Member1> verifies to have 1 peer connection
    And User <Member1> verifies to have CBR connection
    And I wait for 7 seconds
    Then I see call indicator CONSTANT BIT RATE
    When User <Member1> switches video on
    And User <Member1> verifies to have CBR connection
    And I wait for 5 seconds
    Then I see label call indicator CONSTANT BIT RATE
    And I see call indicator CONSTANT BIT RATE

    Examples:
      | TeamOwner | Member1   | CallBackend | TeamName   |
      | user1Name | user2Name | chrome      | Top Secret |

  @TC-4887 @TC-4891 @col1 @cbr @SF.Calls @TSFI.RESTfulAPI @TSFI.Callkit @S0.4 @S3 @S4 @S5 @Security
  Scenario Outline: I want to verify that CBR traffic after receiving 1:1 audio and video call using zcall
    Given I allow microphone access
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <Member1> sets the unique username
    And User Myself has 1:1 conversation with <Member1> in team <TeamName>
    And <Member1> starts 2FA instance using <CallBackend>
    And I enroll the simulator for Touch ID
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open Self profile
    And I open settings screen
    And I select settings item Options
    Then I do not see settings item Variable Bit Rate Encoding
    When I tap X navigation button on Settings page
    And I open conversation "<Member1>" in conversation list
    And <Member1> calls me
    And I tap Accept button on Calling overlay
    And <Member1> verifies that call status to me is changed to active in 20 seconds
    And User <Member1> verifies to have 1 peer connection
    And User <Member1> verifies to send and receive audio
    And User <Member1> verifies to have CBR connection
    And I wait for 7 seconds
    Then I see call indicator CONSTANT BIT RATE
    When User <Member1> switches video on
    And User <Member1> verifies to have CBR connection
    And I wait for 7 seconds
    And I tap on screen to enable video calling overlay
    Then I see label call indicator CONSTANT BIT RATE
    And I see call indicator CONSTANT BIT RATE

    Examples:
      | TeamOwner | Member1   | CallBackend | TeamName       |
      | user1Name | user2Name | zcall_v3    | Do You Read me |
