Feature: Non Fully Connected Graphs

  @C1305774 @C1305778 @federation @NFCG @col3
  Scenario Outline: I should not be able to create a group with both column 1 and  external as a column 3 user
    Given There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerExternal>" with team "<TeamNameExternal>" on external backend
    And User <TeamOwnerColumn3> is connected to <TeamOwnerColumn1>,<TeamOwnerExternal>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwnerColumn3>
    Then I am signed in properly
    When I tap Create Group button on Search UI page
    And I enter group name "<GroupName>" on New Group page
    And I tap Next button on New Group page
    And I select search result item <TeamOwnerColumn1> on Add People page
    And I select search result item <TeamOwnerExternal> on Add People page
    And I tap Create button on Add People page
#  C1305778 I want to see an alert modal when I try to create a group with users from column 1 and external as a column 3 user
    Then I see alert title contains text "Group can't be created"
    And I see alert description contains text "People from backends column-1.wire.link and external.wire.link can't join the same group conversation. To create the group, remove affected participants."

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerExternal | TeamNameColumn1  | TeamNameColumn3 | TeamNameExternal | GroupName      |
      | user1Name        | user2Name        | user3Name         | Team Column1     | Team Column3    | Team Offline     | DB train group |

  @C1305775 @C1305776 @C1305779 @federation @NFCG @col3
  Scenario Outline: I should not be able to add a column 1 user to a group with external users on column 3
    Given There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And There is a team owner "<TeamOwnerExternal>" with team "<TeamNameExternal>" on external backend
    And User <TeamOwnerColumn3> is connected to <TeamOwnerColumn1>,<TeamOwnerExternal>
    And User <TeamOwnerColumn3> has group conversation <GroupExternal> with <TeamOwnerExternal>
    And User <TeamOwnerColumn3> has group conversation <GroupCol1> with <TeamOwnerColumn1>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwnerColumn3>
    Then I am signed in properly
    When I open conversation "<GroupExternal>" in conversation list
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I select search result item <TeamOwnerColumn1> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I close Group Details
    Then I see "<TeamOwnerColumn1> could not be added to the group" system message in the conversation view
# C1305776	I should not be able to add a external user to a group with column 1 users on column 3
    When I navigate back to conversations list
    And I open conversation "<GroupCol1>" in conversation list
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I select search result item <TeamOwnerExternal> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I close Group Details
#  C1305779	I want to see a system message when I try to add external user to a group with users from column 1 as a column 3 user
    Then I see "<TeamOwnerExternal> could not be added to the group" system message in the conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerExternal | TeamNameColumn1  | TeamNameColumn3 | TeamNameExternal | GroupExternal       | GroupCol1       |
      | user1Name        | user2Name        | user3Name         | Team Column1     | Team Column3    | Team Offline     | group With External | group with Col1 |

  @TC-5019 @col1 @NFCG
  Scenario Outline: I should not be able to find external user if I am a user on column 1
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerExternal>" with team "<TeamNameExternal>" on external backend
    And User <TeamOwnerColumn1> is me
    And I enable Federation
    When I login to the default email verified backend as <TeamOwnerColumn1>
    Then I am signed in properly
    When I open search screen
    When I type "@<TeamOwnerExternalUniqueUsername><ColExternalBackendDomain>" in Search UI input field
    Then I see the conversation "<TeamOwnerExternal>" does not exist in Search results

    Examples:
      | TeamOwnerColumn1 | TeamOwnerExternal | TeamNameColumn1 | TeamNameExternal | TeamOwnerExternalUniqueUsername | ColExternalBackendDomain |
      | user1Name        | user2Name         | Avocado         | Banana           | user2UniqueUsername             | @external.wire.link      |

  @C1305780 @C1305781 @federation @NFCG @col3
  Scenario Outline: I want to add a column 1 user to a conversation that previously had an external user participating
    Given There is a team owner "<TeamOwnerColumn3>" with team "<TeamNameColumn3>" on column-3 backend
    And User <TeamOwnerColumn3> adds users <Member1> to team <TeamNameColumn3> with role Member
    And There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerExternal>" with team "<TeamNameExternal>" on external backend
    And User <TeamOwnerColumn3> is connected to <TeamOwnerColumn1>,<TeamOwnerExternal>,<Member1>
    And User <TeamOwnerColumn3> has conversation <GroupExternal> with <Member1>,<TeamOwnerExternal> in team <TeamNameColumn3>
    And User <TeamOwnerColumn3> has conversation <GroupCol1> with <Member1>,<TeamOwnerColumn1> in team <TeamNameColumn3>
    And I enable Federation
    When I login to the default email verified backend as <TeamOwnerColumn3>
    Then I am signed in properly
    When I open conversation "<GroupExternal>" in conversation list
    And User <TeamOwnerColumn3> removes user <TeamOwnerExternal> from group conversation <GroupExternal>
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I select search result item <TeamOwnerColumn1> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I close Group Details
    Then I see "You added <TeamOwnerColumn1>" system message in the conversation view
#    I want to add a external user to a conversation that previously had a column 1 user participating
    When I navigate back to conversations list
    And I open conversation "<GroupCol1>" in conversation list
    And User <TeamOwnerColumn3> removes user <TeamOwnerColumn1> from group conversation <GroupCol1>
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I select search result item <TeamOwnerExternal> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I close Group Details
    Then I see "You added <TeamOwnerExternal>" system message in the conversation view

    Examples:
      | TeamOwnerColumn1 | TeamOwnerColumn3 | TeamOwnerExternal | TeamNameColumn1  | TeamNameColumn3 | TeamNameExternal | GroupExternal       | GroupCol1       | Member1   |
      | user1Name        | user2Name        | user3Name         | Team Column1     | Team Column3    | Team Offline     | group With External | group with Col1 | user4Name |

  @TC-5024 @col1 @NFCG
  Scenario Outline: I should not be able to find column 1 user if I am a user on external
    Given There is a team owner "<TeamOwnerColumn1>" with team "<TeamNameColumn1>" on column-1 backend
    And There is a team owner "<TeamOwnerExternal>" with team "<TeamNameExternal>" on external backend
    And User <TeamOwnerExternal> is me
    And I enable Federation
    And I open external backend deep link in safari
    And I enroll the simulator for Touch ID
    And I tap Proceed button on backend redirection page
    And I enter login <Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <Email>
    And I tap Not Now on save password alert
    And I accept First Time overlay
    And I am signed in properly
    And I perform successful Touch ID
    When I open search screen
    When I type "@<TeamOwnerColumn1UniqueUsername><Col1BackendDomain>" in Search UI input field
    Then I see the conversation "<TeamOwnerColumn1>" does not exist in Search results

    Examples:
      | TeamOwnerColumn1 | TeamOwnerExternal | TeamNameColumn1 | TeamNameExternal | TeamOwnerColumn1UniqueUsername  | Email      | Password       | Col1BackendDomain             |
      | user1Name        | user2Name         | Avocado         | Banana           | user1UniqueUsername             | user2Email | user2Password  | @column-1.wire.link |
