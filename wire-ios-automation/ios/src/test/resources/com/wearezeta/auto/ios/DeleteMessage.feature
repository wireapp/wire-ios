Feature: Delete Message

  @TC-5746 @regression @rc @smoke @deletemessage
  Scenario Outline: I want to verify that deleting is synchronised across own devices when they are online
    Given There are 3 users where <Name> is me
    And I print all created users in the execution log
    And Users add the following devices: {"Myself": [{"name": "<Device>"}], "<Contact1>": [{"name": "<ContactDevice>"}]}
    And User Myself is connected to <Contact1>,<Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>,<Contact2>
    And I login to Wire as <Name>
    And User Myself sends 1 message using device <Device> to user <Contact1>
    And I see conversations list
    And I open conversation "<Contact1>" in conversation list
    When User Myself deletes the recent message from user <Contact1>
    Then I see 0 default messages in the conversation view

    Examples:
      | Name      | Contact1  | Contact2  | Device  | ContactDevice | GroupChatName |
      | user1Name | user2Name | user3Name | Device1 | Device2       | MyGroup       |
