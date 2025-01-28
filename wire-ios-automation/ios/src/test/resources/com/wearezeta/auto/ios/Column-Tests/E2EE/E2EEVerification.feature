Feature: E2EE Verification

  @TC-5908 @unstable @col1 @SF.Messages @TSFI.UserInterface @S0.1 @Security @WPB9932
  Scenario Outline: I want to see conversation degrades with warning when sending files to unverified devices
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <GroupChatName> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{}], "<Member2>": [{}]}
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <Member1> sends 1 default message to conversation <GroupChatName>
    And User <Member1> sends 1 default message to conversation <GroupChatName>
    And I open group conversation "<GroupChatName>" in conversation list
    And I open conversation details
    And I select participant <Member1> on Group Details page
    And I switch to Devices tab on Group participant profile page
    And I open details page of device number 1 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap Back button on Group participant profile page
    And I select participant <Member2> on Group Details page
    And I switch to Devices tab on Group participant profile page
    And I open details page of device number 1 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap Back button on Group participant profile page
    And I tap X button on Group Details page
    And I see 2 default messages in the conversation view
    When Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName2>", "label": "<DeviceLabel2>"}]}
    # Wait for sync
    And I wait for 5 seconds
    And I tap on text input
    And I type the default message and send it
    # Wait for the placeholder
    Then I see alert contains text "started using a new device"
    And I see alert contains text "Do you still want to send your message?"
    When I tap cancel button on degradation alert
    # When @WPB9932 is fixed, the button might be different
    Then I see "Retry" button on the message toolbox in conversation view

    Examples:
      | TeamOwner | Member1   | DeviceName2 | DeviceLabel2 | Member2   | GroupChatName | ResendLabel | Message               | TeamName  |
      | user1Name | user2Name | Device2     | Label2       | user3Name | ThisGroup     | Resend      | not a default message | The Irish |
