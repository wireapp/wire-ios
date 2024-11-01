Feature: Share Location

  @C165160 @C165167 @rc @unstable @landscape
  Scenario Outline: I want to receive and share location
#   TODO AUTOMATION BUG: seems like maps application is not inspectable by Appium anymore
    Given There are 3 user where <Name> is me
    And User Myself is connected to <Contact1>, <Contact2>
    And User Myself has group conversation <GroupChatName> with <Contact1>, <Contact2>
    And User adds the following device: {"<Contact1>": [{"name": "<DeviceName>"}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> shares the default location to user Myself via device <DeviceName>
    And I see conversations list
    When I open conversation "<Contact1>" in conversation list
    Then I see location map container in the conversation view
    When I open group conversation "<GroupChatName>" in conversation list
    And I tap Share Location button from input tools
    And I tap Allow While Using App button on the alert
      # Small delay waiting location detection animation to finish(animation for iPad takes longer)
    And I wait for 5 seconds
    And I tap Send location button from map view
    Then I see location map container in the conversation view
    When I tap on location map in conversation view
    # Wait for map application to be opened
    And I wait for 15 seconds
    And I tap Allow While Using App button on the alert
    Then I see map application is opened

    Examples:
      | Name      | Contact1  | DeviceName | Contact2  | GroupChatName |
      | user1Name | user2Name | device1    | user3Name | ShareAddress  |
