Feature: Search

  @TC-5001 @SF.Usersearch @TSFI.UserInterface @S0.1 @col1 @Security
  Scenario Outline: Local: I should not find a user from another team through full text search, if they have SearchableByOwnTeam enabled
    Given There is a team owner "<UserA>" with team "<TeamNameA>" on column-1 backend
    And  There is a team owner "<UserB>" with team "<TeamNameB>" on column-1 backend
    And User <UserA> is me
    And User <UserB> sets the unique username
    And TeamOwner "<UserB>" sets the search behaviour for SearchVisibilityInbound to SearchableByOwnTeam for team <TeamNameB>
    When I login to the default email verified backend as <UserA>
    Then I am signed in properly
    And  I open search screen
    When I type "<UserB>" in Search UI input field
    Then I do not see contact <UserB> in Search UI
    When I type first 5 letters of user name "<UserB>" into cleared Search UI input field
    Then I do not see contact <UserB> in Search UI
    When I type "@<UserBUniqueUserName>" in cleared Search UI input field
    Then I see contact <UserB> in Search UI

    Examples:
      | UserA     | UserB     | TeamNameA  | TeamNameB     | UserBUniqueUserName |
      | user1Name | user2Name | Searcher   | SearchEnabled | user2UniqueUsername |

  @TC-5002 @SF.Usersearch @TSFI.UserInterface @S0.1 @col1 @Security
  Scenario Outline: Local: I should not find a user from another team by full text search, if my team has SearchVisibilityNoNameOutsideTeam enabled
    Given There is a team owner "<UserA>" with team "<TeamNameA>" on column-1 backend
    And  There is a team owner "<UserB>" with team "<TeamNameB>" on column-1 backend
    And User <UserA> is me
    And User <UserB> sets the unique username
    When I login to the default email verified backend as <UserA>
    Then I am signed in properly
    When TeamOwner "<UserA>" enables the search behaviour for TeamSearchVisibility for team <TeamNameA>
    And TeamOwner "<UserA>" sets the search behaviour for TeamSearchVisibility to SearchVisibilityNoNameOutsideTeam for team <TeamNameA>
    And  I open search screen
    When I type "<UserB>" in Search UI input field
    Then I do not see contact <UserB> in Search UI
    When I type "@<UserBUniqueUserName>" in cleared Search UI input field
    Then I see contact <UserB> in Search UI

    Examples:
      | UserA     | UserB     | TeamNameA  | TeamNameB     | UserBUniqueUserName |
      | user1Name | user2Name | Searcher   | SearchEnabled | user2UniqueUsername |

  @TC-5003 @SF.Usersearch @TSFI.UserInterface @S0.1 @col1 @Security
  Scenario Outline: Local: I should not find a user from another team by email
    Given There is a team owner "<UserA>" with team "<TeamNameA>" on column-1 backend
    And  There is a team owner "<UserB>" with team "<TeamNameB>" on column-1 backend
    And User <UserA> is me
    And User <UserB> sets the unique username
    When I login to the default email verified backend as <UserA>
    Then I am signed in properly
    And  I open search screen
    When I search user <UserB> by email in Search UI input field
    Then I do not see contact <UserB> in Search UI

    Examples:
      | UserA     | UserB     | TeamNameA  | TeamNameB     |
      | user1Name | user2Name | Searcher   | SearchEnabled |

  @TC-5004 @SF.Usersearch @TSFI.UserInterface @S0.1 @S7 @col1 @Security
  Scenario Outline: Remote: I should not find a user from another team on another backend by full text search, if my team has SearchVisibilityNoNameOutsideTeam enabled
    Given There is a team owner "<UserA>" with team "<TeamNameA>" on column-1 backend
    And  There is a team owner "<UserB>" with team "<TeamNameB>" on column-3 backend
    And User <UserA> is me
    And User <UserB> sets the unique username
    When I login to the default email verified backend as <UserA>
    Then I am signed in properly
    When TeamOwner "<UserA>" enables the search behaviour for TeamSearchVisibility for team <TeamNameA>
    And TeamOwner "<UserA>" sets the search behaviour for TeamSearchVisibility to SearchVisibilityNoNameOutsideTeam for team <TeamNameA>
    And  I open search screen
    When I type "<UserB>" in Search UI input field
    Then I do not see contact <UserB> in Search UI
    When I clear Search UI input field
    And I search user <UserB> by handle and domain in Search UI input field
    Then I see contact <UserB> in Search UI

    Examples:
      | UserA     | UserB     | TeamNameA  | TeamNameB     |
      | user1Name | user2Name | Searcher   | SearchEnabled |

  @TC-5005 @SF.Usersearch @TSFI.UserInterface @S0.1 @S7 @col1 @Security
  Scenario Outline: Remote: I should not find a user from another backend by email
    Given There is a team owner "<UserA>" with team "<TeamNameA>" on column-1 backend
    And  There is a team owner "<UserB>" with team "<TeamNameB>" on column-3 backend
    And User <UserA> is me
    And User <UserB> sets the unique username
    When I login to the default email verified backend as <UserA>
    Then I am signed in properly
    And  I open search screen
    When I search user <UserB> by email in Search UI input field
    Then I do not see contact <UserB> in Search UI

    Examples:
      | UserA     | UserB     | TeamNameA  | TeamNameB     |
      | user1Name | user2Name | Searcher   | SearchEnabled |

  ##@C1305584 @SF.Usersearch @TSFI.UserInterface @S0.1 @S7 @col1
  #  #Scenario Outline: Remote: I should not find a user on another backend by full text if their FederatedUserSearchPolicy is exact_handle_search

  @TC-5007 @SF.Usersearch @TSFI.UserInterface @S0.1 @S7 @col1 @Security
  Scenario Outline: Remote: I should not find a user on another backend by full text or handle if their FederatedUserSearchPolicy is no_search
    Given There is a team owner "<UserA>" with team "<TeamNameA>" on column-2 backend
    And There is a team owner "<UserB>" with team "<TeamNameB>" on column-1 backend
    And The search policy is no_search with no team level restriction from column-1 backend to column-2 backend
    And User <UserA> is me
    And User <UserB> sets the unique username
    And I open column-2 backend deep link in safari
    And I enroll the simulator for Touch ID
    And I tap Proceed button on backend redirection page
    And I enter login <UserAEmail> on Login page
    And I enter password <UserAPassword> on Login page
    And I tap Login button on Login page
    And I start verification email monitoring on mailbox <UserAEmail>
    And I tap Not Now on save password alert
    And I see email verification reminder
    And I enter verification code from Email
    And I see First Time overlay
    And I accept First Time overlay
    And I am signed in properly
    And I perform successful Touch ID
    And  I open search screen
    When I search user <UserB> by handle and domain in Search UI input field
    Then I do not see contact <UserB> in Search UI
    When I clear Search UI input field
    And I type "<UserB>" in Search UI input field
    Then I do not see contact <UserB> in Search UI

    Examples:
      | UserA     | UserB     | UserAEmail | UserAPassword | TeamNameA  | TeamNameB     |
      | user1Name | user2Name | user1Email | user1Password | Searcher   | SearchEnabled |