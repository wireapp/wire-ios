Feature: Calling

  @TC-5253 @calling
  Scenario Outline: I want to accept a call through the incoming voice dialogue (Button)
    Given I allow microphone access
    And SFT calling is enabled for backend
    And There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I accept alert if visible
    And I am signed in properly
    And I open conversation "<Contact>" in conversation list
    When <Contact> calls me
    And I see call status message contains "<Contact>"
    And I tap Accept button on Calling overlay
    And I accept microphone access alert on real device
    Then <Contact> verifies that call status to me is changed to active in <Timeout> seconds
    And User <Contact> verifies to have 1 peer connection
    And User <Contact> verifies to send and receive audio

    Examples:
      | Name      | Contact   | CallBackend | Timeout |
      | user1Name | user2Name | chrome      | 30      |
