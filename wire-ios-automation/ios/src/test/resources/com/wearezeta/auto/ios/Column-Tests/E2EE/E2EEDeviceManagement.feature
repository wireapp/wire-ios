Feature: E2EE Device Management

  @TC-5883 @unstable @col1 @SF.Provisioning @TSFI.RESTfulAPI @S0.1 @S2 @BundSecurity
  Scenario Outline: I should not be able to remove device with wrong password
    Given There is a team owner "<Name>" with team "<Name>" on column-1 backend
    And User <Name> is me
    And I login to the default email verified backend as <Name>
    And I perform successful Touch ID
    Then I see conversations list
    And Users of team owned by <Name> adds the following 2FA devices: {"Myself": [{"name": "<DeviceName>", "label": "<DeviceName>"}]}
    And I accept alert if visible
    And I open settings screen
    And I select settings item Devices
    And I tap Edit navigation button on Settings page
    When I tap Delete <DeviceName> button on Settings page
    And I confirm with my WrongPassword the deletion of the device on Settings page
    Then I see wrong password dialog
    When I tap Ok Button on wrong password dialog
    Then I see device <DeviceName> in devices list on Settings page

    Examples:
      | Name      | DeviceName |
      | user1Name | Device1    |
