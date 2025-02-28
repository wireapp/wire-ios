Feature: Log In

  @TC-6256 @rc @regression @login
  Scenario Outline: I want to verify that device management screen is shown appears after registering 7 devices
    Given There is 1 user where <Name> is me
    And Users add the following devices: {"Myself": [{"name": "<DeviceName1>", "label": "<DeviceName1>"}, {"name": "<DeviceName2>", "label": "<DeviceName2>"}, {"name": "<DeviceName3>", "label": "<DeviceName3>"}, {"name": "<DeviceName4>", "label": "<DeviceName4>"}, {"name": "<DeviceName5>", "label": "<DeviceName5>"}, {"name": "<DeviceName6>", "label": "<DeviceName6>"}, {"name": "<DeviceName7>", "label": "<DeviceName7>"}]}
    When I tap Login button on Welcome page
    And I switch to Email Log In tab
    And I enter login MyEmail on Login page
    And I enter password MyPassword on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    And I wait for 3 seconds
    And I wait for 2 seconds
    Then I see Manage Devices overlay
    When I tap Manage Devices button on Devices Overlay
    And I tap Delete for device <DeviceName5>
    And I tap Delete button on Devices Overlay
    And I type "myPassword" text into the alert input field
    And I accept alert
    Then I see conversations list

    Examples:
      | Name      | DeviceName1 | DeviceName2 | DeviceName3 | DeviceName4 | DeviceName5 | DeviceName6 | DeviceName7 |
      | user1Name | Device1     | Device2     | Device3     | Device4     | Device5     | Device6     | Device7     |
