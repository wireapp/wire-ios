Feature: Video Calling

  @C28850 @rc @calling @landscape
  Scenario Outline: I want to verify cancelling Video call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I see conversations list
    When I open conversation "<Contact>" in conversation list
    And I tap Video Call button
    And I accept alert if visible
    And I accept alert if visible
    Then I see call status message contains "<Contact>"
    When I tap Leave button on Calling overlay
    And I do not see Calling overlay
    Then I see "You called" notification in conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C28852 @calling @landscape
  Scenario Outline: I want to verify accepting video call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    When <Contact> starts a video call to me
    And I see call status message contains "<Contact>"
    And I tap Accept button on Calling overlay
    And I accept alert if visible
    Then <Contact> verifies that call status to <Name> is changed to active in <Timeout> seconds

    Examples:
      | Name      | Contact   | CallBackend | Timeout |
      | user1Name | user2Name | chrome      | 60      |

  @C28855 @rc @calling @landscape
  Scenario Outline: I want to verify ignoring Video call [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And I sign in user <Name> with fast login
    And I see conversations list
    When <Contact> starts a video call to me
    And I see call status message contains "<Contact>"
    And I tap Leave button on Calling overlay
    Then I do not see Calling overlay

    Examples:
      | Name      | Contact   | CallBackend |
      | user1Name | user2Name | chrome      |
