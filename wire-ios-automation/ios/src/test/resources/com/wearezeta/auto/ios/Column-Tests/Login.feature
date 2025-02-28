Feature: Log In

  @TC-6256 @col1 @login @SF.Provisioning @TSFI.RESTfulAPI @S0.1 @S2 @Security
  Scenario Outline: I want to verify that device management screen is shown appears after registering 7 devices
    Given There is a team owner "<Name>" with team "<Name>" on column-1 backend
    And User <Name> is me
    And Users of team owned by <Name> adds the following 2FA devices: {"Myself": [{"name": "<DeviceName1>", "label": "<DeviceName1>"}, {"name": "<DeviceName2>", "label": "<DeviceName2>"}, {"name": "<DeviceName3>", "label": "<DeviceName3>"}, {"name": "<DeviceName4>", "label": "<DeviceName4>"}, {"name": "<DeviceName5>", "label": "<DeviceName5>"}, {"name": "<DeviceName6>", "label": "<DeviceName6>"}, {"name": "<DeviceName7>", "label": "<DeviceName7>"}]}
    When I login to the default email verified backend as <Name>
    Then I see Manage Devices overlay
    When I tap Manage Devices button on Devices Overlay
    And I tap Delete for device <DeviceName5>
    And I tap Delete button on Devices Overlay
    And I confirm with my MyPassword the deletion of the device on Settings page
    And I perform successful Touch ID
    Then I see conversations list

    Examples:
      | Name      | DeviceName1 | DeviceName2 | DeviceName3 | DeviceName4 | DeviceName5 | DeviceName6 | DeviceName7 |
      | user1Name | Device1     | Device2     | Device3     | Device4     | Device5     | Device6     | Device7     |
