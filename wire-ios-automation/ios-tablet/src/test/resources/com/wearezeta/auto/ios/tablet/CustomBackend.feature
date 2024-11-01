Feature: Custom Backend

  ###############
  ## Custom BE ##
  ###############

  @C845291 @C845293 @regression @rc @enterpriselogin @switchBackend @landscape
  Scenario Outline: I want to sign in to registered custom backend without a fixed SSO code (Uber)
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User Myself has 1:1 conversation with <Member1> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And I see Welcome page
    When I tap Enterprise Login button on Welcome page
    And I accept alert if visible
    And I type "johnDoe@staging.com" into EmailSSO code field
    And I tap Login button on Enterprise Login popup
    Then I see "<BackendName>" label on Custom backend welcome page
    And I see Log in with Email button on Custom backend welcome page
#    TODO next step does not exist anymore, check why
#    And I see Log in with SSO button on Custom backend welcome page
    When I tap Login with Email button on Custom backend welcome page
    And I sign in user <TeamOwner> with email
    And I accept First Time overlay
    Then I see conversations list
    # Bonus check: able to send and receive messages
    And I open conversation "<Member1>" in conversation list
    And User <Member1> sends 1 "<Message1>" messages to conversation <TeamOwner>
    And I see last message in the conversation view is expected message <Message1>
    And I type the default message and send it
    And I see 1 default message in the conversation view
#    I want to be still logged in to registered custom backend after restarting the app
    When I restart Wire
    And I accept alert if visible
    Then I see 1 default message in the conversation view

    Examples:
      | TeamOwner | TeamName    | Member1   | Member2   | Message1 | BackendName    |
      | user1Name | AwesomeTeam | user2Name | user3Name | Hi       | staging        |

  @C845292 @regression @enterpriselogin @landscape
  Scenario Outline: I want to see error message if I am logged in to wire cloud and try to add different backend account
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User Myself has 1:1 conversation with <Member1> in team <TeamName>
    And I tap Login button on Welcome page
    And I sign in user <TeamOwner> with email
    And I accept First Time overlay
    And I open Self profile
    And I tap Add Account button on Self profile page
    And I tap Enterprise Login button on Welcome page
    And I accept alert if visible
    When I type "abc@staging.com" into EmailSSO code field
    And I tap Login button on Enterprise Login popup
    Then I see error message "<ErrorMessage>" on Enterprise Login popup

    Examples:
      | TeamOwner | TeamName    | Member1   | ErrorMessage                                                                                                                                                                     |
      | user1Name | AwesomeTeam | user2Name | This email is linked to a different server, but the app can only be connected to one server at a time. Please log out of all Wire accounts on this device and try to login again |

  @C754657 @customBackend @regression @landscape
  Scenario Outline: I want to see a confirmation when login to a different backend via deeplink with app is running at background
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> is me
    And I point the app to production backend
    And All other versions of Wire are uninstalled
    And I minimize Wire
    When I open staging backend deep link in safari
    And I see alert contains text "<ExpectedAlertTitle>"
    And I see alert contains text "<ExpectedAlertBody>"
    And I accept alert
    Then I see Custom backend welcome page for backend "staging"
    And I do not see Create Account on Custom Backend Welcome Page
    And I do not see Create Team on Custom Backend Welcome Page
    And I do not see Wire logo on Custom Backend Welcome Page
    When I tap Login with Email button on Custom backend welcome page
    And I sign in user <TeamOwner> with email
    And I accept First Time overlay
    Then I see conversations list

    Examples:
      | TeamOwner | TeamName       | ExpectedAlertTitle | ExpectedAlertBody                                   |
      | user1Name | Sound of Music | Connect to server  | https://staging-nginz-https.zinfra.io/deeplink.json |

  ##########
  ## SSO ##
  #########

  @C845290 @regression @enterpriselogin @landscape
  Scenario Outline: I want to sign in with SSO code after I accidentally used non-registered domain
    Given There is a team owner "<TeamOwner>" with SSO team "<TeamName>" configured for okta
    And User <TeamOwner> adds user <OktaMember1> to okta
    And User <OktaMember1> is me
    And I see Welcome page
    And I tap Enterprise Login button on Welcome page
    And I accept alert if visible
    And I type "john@doe.com" into EmailSSO code field
    When I tap Login button on Enterprise Login popup
    Then I see error message "This email cannot be used" on Enterprise Login popup
    When I type the default SSO code on Enterprise Login popup
    And I tap Login button on Enterprise Login popup
    Then I see okta web view

    Examples:
      | TeamOwner | TeamName    | OktaMember1 |
      | user1Name | AwesomeTeam | user8Name   |

  @C845289 @regression @rc @enterpriselogin @landscape
  Scenario: I want to see an error when I sign in with non registered domain on enterprise sign in
    Given I see Welcome page
    And I tap Enterprise Login button on Welcome page
    And I accept alert if visible
    And I see Enterprise Login popup
    And I see Enterprise Login popup contains text "Please enter your email or SSO code"
    And I see Enterprise Login popup contains button Cancel
    And I see Enterprise Login popup contains button Log In
    When I type "abc@abc.com" into EmailSSO code field
    And I tap Login button on Enterprise Login popup
    Then I see error message "This email cannot be used for enterprise login. Please enter the SSO code to proceed." on Enterprise Login popup
