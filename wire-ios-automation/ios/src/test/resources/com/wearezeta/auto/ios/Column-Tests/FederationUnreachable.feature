Feature: Federation Offline

  ######################
  # Login
  ######################

  @C1305767 @federation @federationOffline
  Scenario Outline: I want to login when I have a group conversation with a user who’s backend is unreachable
    Given Federator for backend column-offline-ios is turned on
    And I wait until the federator pod on column-offline-ios is available
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And I enable Federation
    And Federator for backend column-offline-ios is turned off
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    Then I see conversation <Group> in conversations list
    And I see conversation <TeamOwnerColumn3> in conversations list
    And I do not see conversation <TeamOwnerColumnOffline> in conversations list
#    I want to mention user who is offline and not have my client destroyed
    When I open conversation "<Group>" in conversation list
    And I tap Mention button from input tools
    And I tap Name not available in the suggested mentions list
    And I type the "okay" message and send it
#    will see that the message will not be received by user
    And I see "1 participant from column-offline-ios.wire.link won't get your message" system message in the conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumn3 | TeamNameColumnOffline | Group       |
      | user1Name        | user2Name        | user3Name              | Team Column1     | Team Column3    | Team Offline          | Fruit Salat |

  @C1305766 @federation @federationOffline
  Scenario Outline: I want to login when I have a 1:1 conversation with a user who’s backend is unreachable
    Given I wait until the federator pod on column-offline-ios is available
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> has 1:1 conversation with <TeamOwnerColumnOffline> in team <TeamNameColumn1>
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    And Federator for backend column-offline-ios is turned off
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    Then I do not see conversation <TeamOwnerColumnOffline> in conversations list
    And I see conversation Name not available in conversations list

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline |
      | user1Name        | user3Name              | Team Column1     | Team Offline          |

  @C1305768 @federation @federationOffline
  Scenario Outline: I want to login when I have an outgoing connection request with a user who is unreachable
    Given I wait until the federator pod on column-offline-ios is available
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> sent connection request to <TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    And Federator for backend column-offline-ios is turned off
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    Then I see Pending request link in conversations list
    When I tap Incoming Pending Requests item in conversations list
    Then I see name "Name not available" on Single user Pending incoming connection profile page
    And I see Cancel Request button on Single user Pending outgoing connection page

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline |
      | user1Name        | user3Name              | Team Column1     | Team Offline          |

  @C1305769 @C1305772 @federation @federationOffline
  Scenario Outline: I want to login when I have an incoming connection request from a user who is unreachable
    Given I wait until the federator pod on column-offline-ios is available
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumnOffline> sent connection request to <TeamOwnerColumn1>
    And User <TeamOwnerColumn1> is me
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    And Federator for backend column-offline-ios is turned off
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    Then I see conversation One person waiting in conversations list
    And I see Pending request link in conversations list
#     C1305772 - I want to accept a connection request from a user of a currently unreachable backend
    When I tap Incoming Pending Requests item in conversations list
#    Then I see Unverified user warning on connection request
    And I tap Connect button on Connection Inbox page
    Then I see alert contains text "Error"
    And I see alert contains text "Something went wrong, please try again"
    When I accept alert
    And I tap Ignore button on Connection Inbox page
    Then I do not see Pending request link in conversations list

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline |
      | user1Name        | user3Name              | Team Column1     | Team Offline          |

  @C1305770 @federation @federationOffline
  Scenario Outline: I want to login to my backend when my federator is turned off
    Given I wait until the federator pod on column-offline-ios is available
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And Federator for backend column-offline-ios is turned off
    And User <TeamOwnerColumnOffline> is me
    And I enable Federation
    And I open column-offline-ios backend deep link in safari
    And I accept alert
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    When I tap Login button on Login page
    And I tap Not Now on save password alert
    And I see First Time overlay
    And I wait for 3 seconds
    And I accept First Time overlay
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    Then I am signed in properly
    And I see conversations list

    Examples:
      | TeamOwnerColumnOffline | TeamNameColumnOffline | Email      | Password      |
      | user1Name              | Team Offline          | user1Email | user1Password |
#
#  ######################
#  # Connection requests
#  ######################
#
  @C1305773 @federation @federationOffline
  Scenario Outline: I want to see my outgoing connection request sent to a user who became unavailable after sending the connection request
    Given I wait until the federator pod on column-offline-ios is available
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> sent connection request to <TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<TeamOwnerColumnOffline>" in conversation list
    Then I see Cancel Request button on Single user Pending outgoing connection page
    When Federator for backend column-offline-ios is turned off
    And I restart Wire
    And I accept notification permission alert if visible
    Then I see conversation <TeamOwnerColumnOffline> in conversations list
    When I open conversation "<TeamOwnerColumnOffline>" in conversation list
    Then I see Cancel Request button on Single user Pending outgoing connection page
    When I tap Cancel Request button on Single user Pending outgoing connection page
    Then I do not see conversation <TeamOwnerColumnOffline> in conversations list

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline |
      | user1Name        | user3Name              | Team Column1     | Team Offline          |

  @C1305771 @federation @federationOffline
  Scenario Outline: I should not be able to send a connection request to a user that was cached in search but on unreachable backend
    Given I wait until the federator pod on column-offline-ios is available
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open search screen
    When I type "@<TeamOwnerColumnOfflineUsername><ColOfflineBackendDomain>" in Search UI input field
    Then I see the conversation "<TeamOwnerColumnOffline>" exist in Search results
    Given Federator for backend column-offline-ios is turned off
    When I tap on conversation <TeamOwnerColumnOffline> in search result
    And I tap Connect button on Single user Pending outgoing connection page
    And I see alert contains text "Something went wrong, please try again"

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumnOffline | TeamOwnerColumnOfflineUsername | TeamNameColumn1  | TeamNameColumnOffline | ColOfflineBackendDomain       |
      | user1Name        | user3Name              | user3UniqueUsername            | Team Column1     | Team Offline          | @column-offline-ios.wire.link |

  ########################################
  # adding / removing participants #######
  ########################################

  @C1305748 @C1305747 @federation @federationOffline
  Scenario Outline: I want to add users who are reachable to a group conversation when I select multiple users of which one has an unreachable backend
    And Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn3> adds users <Member1>,<Member2> to team <TeamNameColumn3> with role Member
    And User <TeamOwnerColumnOffline> adds users <Member3> to team <TeamNameColumnOffline> with role Member
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumnOffline>,<TeamOwnerColumn3>,<Member1>,<Member2>,<Member3>
    And User <TeamOwnerColumn1> is me
    And User <TeamOwnerColumn1> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<Group>" in conversation list
    And Federator for backend column-offline-ios is turned off
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I select search result item <Member1> on Group Add People page
    And I select search result item <Member2> on Group Add People page
    And I select search result item <Member3> on Group Add People page
    And I tap Add Participants button on Group Add People page
    Then I see 5 participants avatars on Group Details page
    When I tap X button on Group Details page
#  	I want to see an error system message when I add a user to a group conversation who's backend is unreachable
    Then I see "<Member3> could not be added to the group" system message in the conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline | TeamOwnerColumn3 | TeamNameColumn3 | Member1   | Member2   | Member3   | Group   |
      | user1Name        | user3Name              | Team Column1     | Team Offline          | user2Name        | Team Col3       | user4Name | user5Name | user6Name | heyyall |

  @C1305749 @federation @federationOffline
  Scenario Outline: I want to remove a user from a conversation whos backend is unreachable
    Given Federator for backend column-offline-ios is turned on
    And I wait until the federator pod on column-offline-ios is available
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And Users of team owned by <TeamOwnerColumn3> adds the following 2FA devices: {"<TeamOwnerColumn3>": [{"name": "device3"}]}
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When Federator for backend column-offline-ios is turned off
    And I open conversation "<Group>" in conversation list
    When I open group conversation details
    And I select participant <TeamOwnerColumnOffline> on Group Details page
    And I tap Open Menu button on Group participant profile page
    And I tap Remove From Group… conversation action button
    And I tap Remove From Group conversation action button
    Then I do not see participant name <TeamOwnerColumnOffline> on Group Details page
    When I tap X button on Group Details page
    Then I see "You removed <TeamOwnerColumnOffline>" system message in the conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumn3 | TeamNameColumnOffline | Group       |
      | user1Name        | user2Name        | user3Name              | Team Column1     | Team Column3    | Team Offline          | Fruit Salat |

  @C1305751	@federation @federationOffline
  Scenario Outline: I should not see group conversation messages sent after I was removed from the conversation while my backend was unreachable
    Given Federator for backend column-offline-ios is turned on
    And I wait until the federator pod on column-offline-ios is available
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumnOffline> is connected to <TeamOwnerColumn3>,<TeamOwnerColumn1>
    And User <TeamOwnerColumnOffline> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumn1>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<Group>" in conversation list
    When User <TeamOwnerColumnOffline> sends 1 "This is message 1" message to conversation <Group>
    And Federator for backend column-offline-ios is turned off
    And User <TeamOwnerColumnOffline> sends 1 "This is message 2" message to conversation <Group>
    And User <TeamOwnerColumnOffline> removes user <TeamOwnerColumn1> from group conversation <Group>
    And User <TeamOwnerColumnOffline> sends 1 "This is message 3" message to conversation <Group>
    And Federator for backend column-offline-ios is turned on
    Then I see last message in the conversation view contains expected message This is message 2
    And I see "<TeamOwnerColumnOffline> removed you" system message in the conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumn3 | TeamNameColumnOffline | Group       |
      | user1Name        | user2Name        | user3Name              | Team Column1     | Team Column3    | Team Offline          | Fruit Salat |

  ########################################
  # Backup                         #######
  ########################################

  @C1305805 @C1305806 @C1305807 @C1305808 @C1305809 @history
  Scenario Outline: I want to import a backup that I exported when I had connection requests to backend that is now offline
    Given Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumnOffline> adds users <Member1>,<Member2> to team <TeamNameColumnOffline> with role Member
    And Users of team owned by <TeamOwnerColumn3> adds the following 2FA devices: {"<TeamOwnerColumn3>": [{"name": "device3"}]}
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
#   I want to import a backup that I exported when I had 1:1 conversations to backend that is now offline
    And User <TeamOwnerColumn1> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
#   I want to import a backup that I exported when I had group conversations to backend that is now offline
    And User <TeamOwnerColumn1> has 1:1 conversation with <TeamOwnerColumnOffline> in team <TeamNameColumn1>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <TeamOwnerColumn3> sends 1 "There he is!" message to conversation <Group>
#  C1305808	I want to import a backup while that I  I have a connection requests to backend that is now offline, but was online when I exported the backup
    And User <Member1> sent connection request to <TeamOwnerColumn1>
#  C1305809	I want to import a backup while that I  I have a 1:1 conversation with a backend that is now offline, but was online when I exported the backup
    And User <TeamOwnerColumn1> sent connection request to <Member2>
    And I open settings screen
    And I select settings item Account
    When I select settings item Back Up Conversations
    And I initiate history backup from Settings
    And I wait for 20 seconds
    And I type password "<BackupPassword>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I see correct name of backup file for user <TeamOwnerColumn1> on File Saving Popup
    And I tap Save to Files button on File Saving Popup
    And I tap On My iPhone on File Saving Popup
    And I tap Save button on File Saving Popup
    And I verify history backup for user <TeamOwnerColumn1> from Settings is successfully completed
    And I tap Go back to Account navigation button on Settings page
    And I tap Go back to Settings navigation button on Settings page
    And I select settings item Account
    And I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I wait for 2 seconds
    And I accept alert
    And Federator for backend column-offline-ios is turned off
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I tap Restore from backup button on First Time overlay
    And I tap Choose Backup File button on the alert
    And I tap Browse button twice on bottom of File Choose Dialog
    And I tap On My iPhone on File Choose Dialog
    And I sort files by date on File Choose Dialog
    And I tap file containing <TeamOwnerColumn1Username> in File Choose Dialog
    And I type "<BackupPassword>" text into the alert input field
      # wait for backup to import
    And I wait for 5 seconds
    And I accept alert
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    Then I see conversations list
    And I see conversation <TeamOwnerColumnOffline> in conversations list
    # I see connection request from <Member1> in conversation list
    And I tap Incoming Pending Requests item in conversations list
    And I tap Ignore button on Connection Inbox page
    And I open conversation "<Member2>" in conversation list
    And I see Cancel Request button on Single user Pending outgoing connection page
    # Behaviour Right now: something went wrong when interacting with any of these connection requests
    And I tap Back button on Single user Pending outgoing connection page
    And I open conversation "<Group>" in conversation list
    And I see last message in the conversation view is expected message There he is!
    When I open group conversation details
    Then I see participant names <TeamOwnerColumnOffline> on Group Details page
#   add check for when the user would not be having any metadata\
    When I select participant <TeamOwnerColumnOffline> on Group Details page
    And I tap Open Conversation button on Group participant profile page
    Then I see the conversation with <TeamOwnerColumnOffline> is opened
    When I type the default message and send it
    Then I see User <TeamOwnerColumnOffline> will get your message later in conversation view
    When I tap on Learn more link on delayed message in conversation view
#    add check for opening correct url once url is accessible
# TODO
#    and conversation hosted on foma

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn1Username | BackupPassword  | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline | Email      | Password      | TeamOwnerColumn3 | TeamNameColumn3 | Member1   | Member2   | Group   |
      | user1Name        | user1UniqueUsername      | Aqa123456!Q     | user3Name              | Team Column1     | Team Offline          | user1Email | user1Password | user2Name        | Team Col3       | user4Name | user5Name | heyyall |


  @C1305813 @C1305812 @C1305814 @C1305815 @CC1305816 @history
  Scenario Outline: I want to import a backup while that I I have a group conversation with a backend that is now offline, and was offline when I exported the backup
#   C1305812	I want to import a backup while that I I have a 1:1 conversation with a backend that is now offline, and was offline when I exported the backup
#C1305813	I want to import a backup while that I I have a group conversation with a backend that is now offline, and was offline when I exported the backup
#C1305814	I want to import a backup while that I I have a 1:1 conversation with a backend that is now online, but was offline when I exported the backup
#C1305815	I want to import a backup while that I I have a group conversation with a backend that is now online, but was offline when I exported the backup
#C1305816	I want to import a backup while that I I have a connection requests to backend that is now online, but was offline when I exported the backup
    Given Federator for backend column-offline-ios is turned on
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumnOffline> adds users <Member1>,<Member2>,<Member3> to team <TeamNameColumnOffline> with role Member
    And Users of team owned by <TeamOwnerColumn3> adds the following 2FA devices: {"<TeamOwnerColumn3>": [{"name": "device3"}]}
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumn3>,<TeamOwnerColumnOffline>,<Member3>
    And User <TeamOwnerColumn1> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> has 1:1 conversation with <TeamOwnerColumnOffline> in team <TeamNameColumn1>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When User <TeamOwnerColumn3> sends 1 "There he is!" message to conversation <Group>
    And User <Member1> sent connection request to <TeamOwnerColumn1>
    And User <TeamOwnerColumn1> sent connection request to <Member2>
    And User <TeamOwnerColumn1> blocks user <Member3>
    And Federator for backend column-offline-ios is turned off
    And I open conversation "<Group>" in conversation list
    And I type the default message and send it
    And I navigate back to conversations list
    And I open Self profile
    And I open settings screen
    And I select settings item Account
    And I select settings item Back Up Conversations
    And I initiate history backup from Settings
#    Wait for creating backup
    And I wait for 20 seconds
    And I type password "<BackupPassword>" on Backup password overlay
    And I tap Next button on Backup password overlay
    And I see correct name of backup file for user <TeamOwnerColumn1> on File Saving Popup
    And I tap Save to Files button on File Saving Popup
    And I tap On My iPhone on File Saving Popup
    And I tap Save button on File Saving Popup
    And I verify history backup for user <TeamOwnerColumn1> from Settings is successfully completed
    And I tap Go back to Account navigation button on Settings page
    And I tap Go back to Settings navigation button on Settings page
    And I select settings item Account
    And I select settings item Log Out
    And I type "<Password>" text into the alert input field
    And I wait for 2 seconds
    And I accept alert
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    When I tap Restore from backup button on First Time overlay
    And I tap Choose Backup File button on the alert
    And I tap Browse button twice on bottom of File Choose Dialog
    And I tap On My iPhone on File Choose Dialog
    And I sort files by date on File Choose Dialog
    And I tap file containing <TeamOwnerColumn1Username> in File Choose Dialog
    And I type "<BackupPassword>" text into the alert input field
      # wait for backup to import
    And I wait for 2 seconds
    And I accept alert
    And I see Encryption At Rest overlay
    And I type password on the Encryption At Rest overlay input
    And I press enter on the Encryption At Rest overlay input
    Then I see conversations list
    # I see connection request from <Member1> in conversation list
    And I tap Incoming Pending Requests item in conversations list
#    Wait as backend is very slow in recognizing this request
    And I tap Ignore button on Connection Inbox page
    And I wait for 20 seconds
    And I open conversation "<Member2>" in conversation list
    And I see Cancel Request button on Single user Pending outgoing connection page
    And I tap Back button on Single user Pending outgoing connection page
    And I open conversation "<Group>" in conversation list
    And I see last message in the conversation view is expected message 1 message
    When I open group conversation details
    Then I see participant names <TeamOwnerColumnOffline> on Group Details page
#   add check for when the user would not be having any metadata\
    When I select participant <TeamOwnerColumnOffline> on Group Details page
    And I tap Open Conversation button on Group participant profile page
    Then I see the conversation with <TeamOwnerColumnOffline> is opened
    When I type the default message and send it
    Then I see User <TeamOwnerColumnOffline> will get your message later in conversation view
    When I tap on Learn more link on delayed message in conversation view
#    add check for opening correct url once url is accessible

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn1Username | BackupPassword  | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumnOffline | Email      | Password      | TeamOwnerColumn3 | TeamNameColumn3 | Member1   | Member2   | Member3   | Group   |
      | user1Name        | user1UniqueUsername      | Aqa123456!Q     | user3Name              | Team Column1     | Team Offline          | user1Email | user1Password | user2Name        | Team Col3       | user4Name | user5Name | user6Name | heyyall |

#  @C1305753
#  Scenario Outline: I want to see ephemeral messages disappear after the timer expired when sending backend has become unreachable after sending

###############
# Messaging ###
###############

  @C1305754 @C1305757 @federation @federationOffline
  Scenario Outline: I want to receive messages in a group conversation of which one user is unreachable
    Given Federator for backend column-offline-ios is turned on
    And I wait until the federator pod on column-offline-ios is available
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerColumnOffline>" with team "<TeamNameColumnOffline>" on column-offline-ios backend
    And User <TeamOwnerColumn1> is connected to <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And User <TeamOwnerColumn1> has group conversation <Group> with <TeamOwnerColumn3>,<TeamOwnerColumnOffline>
    And Users of team owned by <TeamOwnerColumn3> adds the following 2FA devices: {"<TeamOwnerColumn3>": [{"name": "device3"}]}
    And I enable Federation
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When Federator for backend column-offline-ios is turned off
    When User <TeamOwnerColumn3> sends 1 "There he is!" message to conversation <Group>
    And I open conversation "<Group>" in conversation list
    Then I see last message in the conversation view is expected message There he is!
#    I want to send messages in a group conversation of which one user is unreachable
    When I type the "How are you" message and send it
    Then I see User <TeamOwnerColumnOffline> will get your message later in conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerColumnOffline | TeamNameColumn1  | TeamNameColumn3 | TeamNameColumnOffline | Group       |
      | user1Name        | user2Name        | user3Name              | Team Column1     | Team Column3    | Team Offline          | Fruit Salat |