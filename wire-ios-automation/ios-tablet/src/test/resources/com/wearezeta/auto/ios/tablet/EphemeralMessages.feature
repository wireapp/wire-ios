Feature: Ephemeral Messages

  @C318642 @regression @landscape
  Scenario Outline: I want to verify the message is deleted on the sender side when it's read on the receiver side
    Given There are 2 user where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{"name": "<DeviceName>", "label": "<DeviceName>"}]}
    And I sign in user <Name> with fast login
    And I see conversations list
    And I open conversation "<Contact>" in conversation list
    And I tap Hourglass button in conversation view
    And I set self deleting message expiration timer to <Timeout> seconds on conversation view
    # This is to close expiration timer popup
    And I tap at 50%,50% of the viewport size
    And I type the default message and send it
    And I see 1 default message in the conversation view
    When User <Contact> received the recent message from user Myself
    And I wait for 11 seconds
    Then I see 0 default messages in the conversation view

    Examples:
      | Name      | Contact   | Timeout | DeviceName    |
      | user1Name | user2Name | 10      | ContactDevice |
