Feature: MLS Col1

  @CC1312749 @C1312729 @C1312730 @col3 @mlscol1
  Scenario Outline: I want to create a MLS group conversation with another team and exchange messages before removing participants
    Given I enable MLS support
    And There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>" on column-3 backend
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <TeamOwner2> adds users <Member2> to team <TeamName2> with role Member
    And User <TeamOwner> configures MLS for team "<TeamName>"
    And User <TeamOwner2> configures MLS for team "<TeamName2>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName>", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName1>", "label": "C2"}]}
    And Users of team owned by <TeamOwner2> adds the following 2FA devices: {"<Member2>": [{"name": "device4", "label": "C1"}]}
    And Users of team owned by <TeamOwner2> adds the following 2FA devices: {"<TeamOwner2>": [{"name": "<device23>", "label": "C2"}]}
    And Users <TeamOwner> claims key packages
    And Users <Member1> claims key packages
    And Users <Member2> claims key packages
    And Users <TeamOwner2> claims key packages
    And User <Member1> is me
    And I enable API versioning 5
    And User Myself is connected to <TeamOwner2>,<Member2>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I wait for 10 seconds
#    And I see Encryption At Rest overlay
#    And I type password on the Encryption At Rest overlay input
#    And I press enter on the Encryption At Rest overlay input
#    And I do not see Encryption At Rest overlay
    And I am signed in properly
    And  I open search screen
    And I open create group screen
    And I enter group name "<GroupName>" on New Group page
    When I expand conversation options on New Group page
    When I tap Protocol option on New Group page
    And I tap MLS option on New Group page
    When I tap Next button on New Group page
    And I type "<TeamOwner>" in search input field on Add People page
    And I select search result item <TeamOwner> on Add People page
    And I type "<TeamOwner2>" in search input field on Add People page
    And I select search result item <TeamOwner2> on Add People page
    And I tap Create button on Add People page
    Then I see "<NewIntroductionMessage> <GroupName>" system message in the conversation view
   # And Conversation <GroupName> from user <Member1> uses mls protocol
    When I navigate back to conversations list
#   C1312724 I want to add users to MLS group
#    I want to create MLS conversation and add federated users
    Then I see conversation <GroupName> in conversations list
    When I open conversation "<GroupName>" in conversation list
    And I open conversation details
    And I tap Add People button on Group Details page
    And I type search query "<Member2>" on Group Add People page
    And I select search result item <Member2> on Group Add People page
    And I tap Done keyboard button
    Then I see participant names <TeamOwner>,<Member2>,<TeamOwner2> on Group Details page
    When I tap X button on Group Details page
    Then I see "You added <Member2>" system message in the conversation view
#    C1312730	I want to create MLS conversation and remove users on federated backend
    When I open group conversation details
    And I select participant <Member2> on Group Details page
    And I tap Open Menu button on Group participant profile page
    And I tap Remove From Group… conversation action button
    And I tap Remove From Group conversation action button
    Then I do not see participant name <Member2> on Group Details page
    When I tap X button on Group Details page
    Then I see "You removed <Member2>" system message in the conversation view

    Examples:
      | TeamOwner | Member1   | Member2   | TeamOwner2 | TeamName | GroupName | TeamName2    | NewIntroductionMessage       | DeviceName    | Email      | Password        | DeviceName1      |
      | user1Name | user2Name | user4Name | user3Name  | Pyramid  | MLS Group | Guest Team   | You started the conversation | ContactDevice | user2Email | user2Password   | TeamOwnerDevice1 |

  @C1312728 @C1312724 @C1312728 @C1312748 @C1312725 @col3 @mlscol1
  Scenario Outline: I want to create a group with a guest and react to each others messages before and after disabling MLS for the whole team
    Given I enable MLS support
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> configures MLS for team "<TeamName>"
    And User <TeamOwner2> configures MLS for team "<TeamName2>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName>", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member2>": [{"name": "device4", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName1>", "label": "C2"}]}
    And Users of team owned by <TeamOwner2> adds the following 2FA devices: {"<TeamOwner2>": [{"name": "<device23>", "label": "C2"}]}
    And Users <TeamOwner> claims key packages
    And Users <Member1> claims key packages
    And Users <Member2> claims key packages
    And Users <TeamOwner2> claims key packages
    And User <Member1> is me
    And I enable API versioning 5
    And User Myself is connected to <TeamOwner2>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    #And I see Encryption At Rest overlay
    #And I type password on the Encryption At Rest overlay input
    #And I press enter on the Encryption At Rest overlay input
    #And I do not see Encryption At Rest overlay
    And I wait for 10 seconds
    And I am signed in properly
    And  I open search screen
    And I open create group screen
    And I enter group name "<GroupName>" on New Group page
    # C1312728 I want to see a protocol dropdown during group creation as MLS enabled member
    When I expand conversation options on New Group page
    Then I see Guests option on group creation view
    And I see Services option on group creation view
    And I swipe up on Group Details page
#    And I see the Read Receipts toggle on New Group page
    And I see Protocol option on New Group page
    And I see Proteus value in Protocol option on New Group page
    When I tap Protocol option on New Group page
    And I tap MLS option on New Group page
    Then I see MLS value in Protocol option on New Group page
    When I tap Next button on New Group page
    And I type "<TeamOwner>" in search input field on Add People page
    And I select search result item <TeamOwner> on Add People page
    And I type "<TeamOwner2>" in search input field on Add People page
    And I select search result item <TeamOwner2> on Add People page
    And I tap Create button on Add People page
    Then I see "<NewIntroductionMessage> <GroupName>" system message in the conversation view
   # And Conversation <GroupName> from user <Member1> uses mls protocol
    When I navigate back to conversations list
#   C1312724 I want to add users to MLS group
    Then I see conversation <GroupName> in conversations list
    When I open conversation "<GroupName>" in conversation list
    And I open conversation details
    And I tap Add People button on Group Details page
    And I type search query "<Member2>" on Group Add People page
    And I select search result item <Member2> on Group Add People page
    And I tap Done keyboard button
    Then I see participant names <TeamOwner>,<Member2>,<TeamOwner2> on Group Details page
    When I tap X button on Group Details page
    Then I see "You added <Member2>" system message in the conversation view
        # I want to send and receive messages in the MLS conversation
    When User <Member2> sends 1 default message to conversation <GroupName>
    Then I see 1 default messages in the conversation view
#    When User <Member1> sends 1 image file <Picture> to conversation <GroupName>
    When I type the default message and send it
    Then I see 2 default messages in the conversation view
        # C1312748 I want to see read receipts in the MLS conversation
    When User <TeamOwner> marks the recent message as read in conversation <GroupName> via device <DeviceName1>
    And I see that recent message is seen by 1 persons
    And  I long tap default message in conversation view
    When I tap on Details on edit menu
    Then I see user <TeamOwner> in the Seen list
    When I close the message details
    When I open group conversation details
    And I select participant <Member2> on Group Details page
    And I tap Open Menu button on Group participant profile page
    And I tap Remove From Group… conversation action button
    And I tap Remove From Group conversation action button
    Then I do not see participant name <Member2> on Group Details page
    When I tap X button on Group Details page
    Then I see "You removed <Member2>" system message in the conversation view

    Examples:
      | TeamOwner | Member1   | Member2   | TeamOwner2 | TeamName | GroupName | TeamName2    | NewIntroductionMessage       | DeviceName    | Email      | Password        | DeviceName1      |
      | user1Name | user2Name | user4Name | user3Name  | Pyramid  | MLS Group | Guest Team   | You started the conversation | ContactDevice | user2Email | user2Password   | TeamOwnerDevice1 |

  @C1312731 @C1312732 @col3 @mlscol1
  Scenario Outline: I want to send and receive reactions in MLS group conversation
    Given I enable MLS support
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> configures MLS for team "<TeamName>"
    And User <TeamOwner2> configures MLS for team "<TeamName2>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName>", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member2>": [{"name": "device4", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName1>", "label": "C2"}]}
    And Users of team owned by <TeamOwner2> adds the following 2FA devices: {"<TeamOwner2>": [{"name": "<device23>", "label": "C2"}]}
    And Users <TeamOwner> claims key packages
    And Users <Member1> claims key packages
    And Users <Member2> claims key packages
    And Users <TeamOwner2> claims key packages
    And User <Member1> is me
    And I enable API versioning 5
    And User Myself is connected to <TeamOwner2>
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    #And I see Encryption At Rest overlay
    #And I type password on the Encryption At Rest overlay input
    #And I press enter on the Encryption At Rest overlay input
    #And I do not see Encryption At Rest overlay
    And I wait for 10 seconds
    And I am signed in properly
    When I open search screen
    And I open create group screen
    And I enter group name "<GroupName>" on New Group page
    When I expand conversation options on New Group page
    When I tap Protocol option on New Group page
    And I tap MLS option on New Group page
    When I tap Next button on New Group page
    And I type "<TeamOwner>" in search input field on Add People page
    And I select search result item <TeamOwner> on Add People page
    And I type "<TeamOwner2>" in search input field on Add People page
    And I select search result item <TeamOwner2> on Add People page
    And I tap Create button on Add People page
    Then I see "<NewIntroductionMessage> <GroupName>" system message in the conversation view
    When User <TeamOwner> sends 1 default message to conversation <GroupName>
    And I long tap default message in conversation view
    And I tap on ❤️ reaction in quick reactions
    And I see ❤️ reaction in the conversation view
    And I long tap default message in conversation view
    And I tap on ❤️ reaction in quick reactions
    Then I do not see ❤️ reaction in the conversation view
    When I type the default message and send it
    And User <TeamOwner> likes the recent message from group conversation <GroupName>
    And User <TeamOwner> marks the recent message as read in conversation <GroupName> via device <DeviceName1>
    And I see ❤️ reaction in the conversation view

    Examples:
      | TeamOwner | Member1   | Member2   | TeamOwner2 | TeamName | GroupName | TeamName2    | NewIntroductionMessage       | DeviceName    | Email      | Password        | DeviceName1      |
      | user1Name | user2Name | user4Name | user3Name  | Pyramid  | MLS Group | Guest Team   | You started the conversation | ContactDevice | user2Email | user2Password   | TeamOwnerDevice1 |

  @C1312733 @C1312734 @C1312757 @C1312758 @mlscol1
  Scenario Outline: I want to add users to a MLS group conversation as a group admin
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And There is a team owner "<TeamOwner2>" with team "<TeamName2>"
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> configures MLS for team "<TeamName>"
    And User <TeamOwner2> configures MLS for team "<TeamName2>"
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member1>": [{"name": "<DeviceName>", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<Member2>": [{"name": "device4", "label": "C1"}]}
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName1>", "label": "C2"}]}
    And Users of team owned by <TeamOwner2> adds the following 2FA devices: {"<TeamOwner2>": [{"name": "<device23>", "label": "C2"}]}
    And Users <TeamOwner> claims key packages
    And Users <Member1> claims key packages
    And Users <Member2> claims key packages
    And Users <TeamOwner2> claims key packages
    And User <Member1> is me
    And I enable API versioning 5
    And User Myself is connected to <TeamOwner2>
    And User <TeamOwner> has MLS conversation "<GroupName>" with <Member1>
    And User <TeamOwner> changes users <Member1> to role Admin for conversation "<GroupName>"
    And I open default backend via deep link in safari
    And I tap Proceed button on backend redirection page
    And I tap Login with Email button on Custom backend welcome page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    #And I see Encryption At Rest overlay
    #And I type password on the Encryption At Rest overlay input
    #And I press enter on the Encryption At Rest overlay input
    #And I do not see Encryption At Rest overlay
    And I am signed in properly
#  C1312735  I want to see and exchange messages in a MLS group which was created before I logged in
    Then I see conversation <GroupName> in conversations list
    When I open conversation "<GroupName>" in conversation list
    And I type the default message and send it
    Then I see 1 default messages in the conversation view
    When User <TeamOwner> sends 1 default message to conversation <GroupName>
    Then I see 2 default messages in the conversation view
    And I open conversation details
#  C1312757	I want to be able to add a user to MLS conversation after I have been promoted to Admin
    And I tap Add People button on Group Details page
    And I type search query "<Member2>" on Group Add People page
    And I select search result item <Member2> on Group Add People page
    And I tap Done keyboard button
    Then I see participant names <TeamOwner>,<Member2>,<TeamOwner2> on Group Details page
    When I tap X button on Group Details page
    Then I see "You added <Member2>" system message in the conversation view
    #C1312734 I want to remove users from a MLS group conversation as a group admin
    #C1312758	I want to be able to remove a user to MLS conversation after I have been promoted to Admin
    When I open group conversation details
    And I select participant <Member2> on Group Details page
    And I tap Open Menu button on Group participant profile page
    And I tap Remove From Group… conversation action button
    And I tap Remove From Group conversation action button
    Then I do not see participant name <Member2> on Group Details page
    When I tap X button on Group Details page
    Then I see "You removed <Member2>" system message in the conversation view

    Examples:
      | TeamOwner | Member1   | Member2   | TeamOwner2 | TeamName | GroupName | TeamName2    | NewIntroductionMessage       | DeviceName    | Email      | Password        | DeviceName1      |
      | user1Name | user2Name | user4Name | user3Name  | Pyramid  | MLS Group | Guest Team   | You started the conversation | ContactDevice | user2Email | user2Password   | TeamOwnerDevice1 |
