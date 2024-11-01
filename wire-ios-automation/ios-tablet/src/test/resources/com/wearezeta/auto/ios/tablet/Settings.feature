Feature: Settings

  @C2906 @regression @settings @rc @landscape
  Scenario Outline: I want to attempt to open About screen in settings [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    When I open Self profile
    And I open settings screen
    And I select settings item About
    Then I see settings item Privacy Policy
    And I see settings item Terms of Use
    And I see settings item License Information
    When I tap X navigation button on Settings page
    Then I see conversations list

    Examples:
      | Name      |
      | user1Name |

  @C2907 @regression @settings @landscape
  Scenario Outline: I want to verify reset password page is accessible from settings [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    When I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Reset Password
    Then I see "Change Password" web page

    Examples:
      | Name      |
      | user1Name |

  @C2908 @regression @settings @landscape
  Scenario Outline: I want to verify default value for sound settings is all [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    When I open Self profile
    And I open settings screen
    And I select settings item Options
    Then I verify the value of settings item Sound Alerts equals to "All"

    Examples:
      | Name      |
      | user1Name |

  @C2909 @regression @settings @landscape
  Scenario Outline: I want to verify you can access Help site within the app [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    When I open Self profile
    And I open settings screen
    And I select settings item Support
    And I select settings item Wire Support Website
    Then I do not see settings item Wire Support Website
    # This does not work on tablet :(
    # And I wait for 7 seconds
    # Then I see Support web page

    Examples:
      | Name      |
      | user1Name |

  @C145961 @rc @regression @settings @useSpecialEmail @landscape
  Scenario Outline: I want to verify deleting the account registered by email [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I tap Login button on Welcome page
    And I Sign in on tablet using my email
    And I accept First Time overlay
    And I am signed in properly
    And I accept Help us make Wire better popup
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    When I start waiting for <Name> account removal notification
    And I select settings item Delete Account
      # Delete confirmation
    And I accept alert
      # Session expired
    And I accept alert
    Then I see Welcome page
    And I verify account removal notification is received

    Examples:
      | Name      |
      | user1Name |

  @C579238 @regression @settings @landscape
  Scenario Outline: I want to verify max limit in 64 chars [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Name
    And I set "<NewUsername>" value to Name input field on Settings page
    And I tap Return button on the keyboard
    Then I verify the value of settings item Name equals to "<NewUsername>"
    When I select settings item Name
    And I set "<NewUsername1>" value to Name input field on Settings page
    And I tap Return button on the keyboard
    Then I verify the value of settings item Name equals to "<NewUsername1>"

    Examples:
      | Name      | NewUsername                                                          | NewUsername1                                                     |
      | user1Name | mynewusernamewithmorethan64characters3424245345345354353452345234535 | mynewusernamewithmorethan64characters342424534534535435345234523 |

  @C2875 @rc @unstable @settings @landscape
  Scenario Outline: I want to change my profile picture [LANDSCAPE] (fails on jenkins)
    Given There is 1 user where <Name> is me
    And I tap Login button on Welcome page
    And I sign in user <Name> with email
    And I accept First Time overlay
    And I accept Help us make Wire better popup
    And I open Self profile
    # This takes some time on CI
    And I wait for 5 seconds
#    And I remember the picture on Self profile page
    When I tap my picture preview on Self profile page
    Then I see Choose from library button on change profile pop up
    And I see Take Photo button on Camera page
    When I tap Choose from library button on change profile pop up
    # Wait for Camera Roll opening animation
    And I wait for 3 seconds
    And I accept alert if visible
    And I select a picture from Camera Roll
    And I accept alert if visible
    And I tap OK button on Picture preview page on iPAD
    Then I see the picture is changed on Self profile page
    # Wait until profile picture is fully loaded
    When I wait for 7 seconds
    And I select settings item Account
    And I select settings item Picture
    And I remember my current profile picture
    Then I see Choose from library button on change profile pop up
    And I see Take Photo button on Camera page
    When I tap Choose from library button on change profile pop up
      # Wait for camera toll opening animation
    And I wait for 3 seconds
    And I accept alert if visible
    And I select a picture from Camera Roll
    And I tap Confirm button on Picture preview page
    Then I wait up to <Timeout> seconds until my profile picture is changed

    Examples:
      | Name      | Timeout |
      | user1Name | 60      |

  @C579237 @regression @settings
  Scenario Outline: I want to enter a name with 0 chars [PORTRAIT]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    And I rotate UI to portrait
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Name
    When I clear Name input field on Settings page
    And I wait for 3 seconds
    And I tap Return button on the keyboard
    Then I see alert contains text "<ExpectedAlertText>"
    And I accept alert

    Examples:
      | Name      | ExpectedAlertText     |
      | user1Name | At least 2 characters |

  @C579236 @rc @regression @settings @landscape
  Scenario Outline: I want to change name [LANDSCAPE]
    Given There are 1 user where <Name> is me
    And I sign in user <Name> with fast login
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Name
    When I set "<NewUsername>" value to Name input field on Settings page
    And I tap Return button on the keyboard
    And I tap X navigation button on Settings page
    And I see conversations list
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    Then I verify the value of settings item Name equals to "<NewUsername>"

    Examples:
      | Name      | NewUsername |
      | user1Name | NewName     |

  @C2856 @regression @settings
  Scenario Outline: I want to verify changing and applying accent color [PORTRAIT]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User Myself changes accent color to <Color1>
    And User Myself removes their avatar picture
    And I rotate UI to portrait
    And I sign in user <Name> with fast login
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    When I select settings item Color
    And I remember the state of Color Picker
    And I set my accent color to <Color2> on Settings page
    And I close accent color picker on Settings page
    And I select settings item Color
    Then I verify the state of Color Picker is changed

    Examples:
      | Name      | Color1 | Color2          | Contact   |
      | user1Name | Violet | StrongLimeGreen | user2Name |

  @C2855 @rc @regression @settings @landscape
  Scenario Outline: I want to verify theme switcher is not shown on the self profile [LANDSCAPE]
    Given There is 1 user where <Name> is me
    And I sign in user <Name> with fast login
    And I open Self profile
    And I open settings screen
    When I select settings item Options
    Then I do not see settings item <ThemeItemName>

    Examples:
      | Name      | ThemeItemName |
      | user1Name | Dark theme    |

  @C404412 @rc @regression @settings @useSpecialEmail @landscape
  Scenario Outline: I want to verify changing email when phone is not assigned [LANDSCAPE]
    Given There is 1 user with email address only where <Name> is me
    And I sign in user <Name> with fast login
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Email
    When I start activation email monitoring on mailbox <NewEmail>
    And I change email address to <NewEmail> on Settings page
    And I tap Save navigation button on Settings page
      # Wait for sync
    And I wait for 3 seconds
    And I verify email address <NewEmail> for Myself
    And I wait until the UI detects successful email activation on Settings page
    Then I verify the value of settings item Email equals to "<NewEmail>"
    And I verify user's Myself email on the backend is equal to <NewEmail>

    Examples:
      | Password      | Name      | NewEmail   |
      | user1Password | user1Name | user2Email |
