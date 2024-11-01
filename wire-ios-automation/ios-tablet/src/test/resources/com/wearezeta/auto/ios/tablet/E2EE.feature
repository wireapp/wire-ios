Feature: E2EE

  @C145965 @rc @regression @landscape
  Scenario Outline: I want to verify device verification [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact1>
    And Users add the following devices: {"<Contact1>": [{"name": "<DeviceName1>"}, {"name": "<DeviceName2>"}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends 1 default message to conversation Myself
    When I open conversation "<Contact1>" in conversation list
    Then I do not see shield icon in the conversation view
    When I open conversation details
    And I switch to Devices tab on Single user profile page
    And I open details page of device number 1 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I open details page of device number 2 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap X button on Single user profile page
    Then I see shield icon in the conversation view

    Examples:
      | Name      | Contact1  | DeviceName1 | DeviceName2 |
      | user1Name | user2Name | Device1     | Device2     |

  @C145964 @rc @regression @landscape
  Scenario Outline: I want to verify system message appearance in case of using a new device by you [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact1>
    And User adds the following device: {"<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends 1 default message to conversation Myself
    And I open conversation "<Contact1>" in conversation list
    And I open conversation details
    And I switch to Devices tab on Single user profile page
    And I open details page of device number 1 on Devices tab
    When I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap X button on Single user profile page
    And User adds the following device: {"Myself": [{"name": "<DeviceName2>", "label": "<DeviceLabel2>"}]}
    Then I do not see shield icon in the conversation view
    And I see "<StartedUsingMsg>" system message in the conversation view

    Examples:
      | Name      | Contact1  | DeviceName2 | DeviceLabel2 | StartedUsingMsg                |
      | user1Name | user2Name | Device2     | Label2       | You started using a new device |

  @C455478 @regression @landscape
  Scenario Outline: I want to verify calling anyway when friend added a new device
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact1>
    And User adds the following device: {"<Contact1>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact1> sends 1 default message to conversation Myself
    And I open conversation "<Contact1>" in conversation list
    And I open conversation details
    And I switch to Devices tab on Single user profile page
    And I open details page of device number 1 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap X button on Single user profile page
    And I see shield icon in the conversation view
    And I see "<VerificationMsg>" system message in the conversation view
    And Users add the following devices: {"<Contact1>": [{"name": "<Device1>", "label": "<Device1label>"}]}
    When I tap Audio Call button
    And I accept alert if visible
    Then I see degradation alert contains text New Device
    And I wait for 3 seconds
    When I tap call anyway on degradation alert
    Then I see Calling overlay


    Examples:
      | Name      | Contact1  | Device1 | Device1label | VerificationMsg               |
      | user1Name | user2Name | Device1 | Device1label | All fingerprints are verified |

  @C455482 @unstable @landscape
  Scenario Outline: I want to verify degradation shield is displayed on incoming call when new device is added by me [LANDSCAPE]
    Given There are 2 user where <Name> is me
    And User Myself is connected to <Contact>
    And User <Contact> sets the unique username
    And <Contact> starts instance using <CallBackend>
    And All other versions of Wire are uninstalled
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    And I open conversation details
    And I switch to Devices tab on Single user profile page
    And I open details page of device number 1 on Devices tab
    And I tap Verify switcher on Device Details page
    And I tap Back button on Device Details page
    And I tap X button on Single user profile page
    And I see shield icon in the conversation view
    And I see "<VerificationMsg>" system message in the conversation view
    And User adds the following devices: {"Myself": [{"name": "<Device1>", "label": "<Device1label>"}]}
    And I see "<DegradedMsg>" system message in the conversation view
    And <Contact> calls me
        # Wait for the call to connect
    And I wait for 5 seconds
    And I tap Accept button on Calling overlay
    When I tap OK button on permission alert if visible
    Then I see alert about New device
    And I accept alert if visible
    And <Contact> stops outgoing call to me
    Then I do not see Calling overlay
    When <Contact> calls me
        # Wait for the call to connect
    And I tap Accept button on Calling overlay
    When I tap OK button on permission alert if visible
    Then I see alert about New device
    And I accept alert if visible
    And I wait for 5 seconds
    Then I see alert about New device
    When I accept alert if visible
        # Timeout to wait for call get connected
    Then <Contact> verifies that call status to me is changed to active in <Timeout> seconds

    Examples:
      | Name      | Contact   | CallBackend | Device1 | Device1label | VerificationMsg               | DegradedMsg                    | Timeout |
      | user1Name | user2Name | chrome      | Device1 | Device1label | All fingerprints are verified | You started using a new device | 5       |
