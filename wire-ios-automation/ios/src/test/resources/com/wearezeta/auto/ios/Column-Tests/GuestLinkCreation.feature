Feature: Guest Link Creation

  @TC-4980 @col1 @SF.VSNFDLABEL @TSFI.UserInterface @TSFI.Federate @S0.1 @S7 @BundSecurity @shouldbeUI
  Scenario Outline: I should not see Create Guest Link option on group details page when Guest Links are disabled on backend
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <GroupConversationWithClassified> with <Member1>,<Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <TeamOwner>
    Then I am signed in properly
    When I open conversation "<GroupConversationWithClassified>" in conversation list
    And I open group conversation details
    And I tap Guest Options on Group Details page
    Then I do not see Create Link button on Guest Options page

    Examples:
      | TeamOwner | TeamName              | Member1   | Member2   | GroupConversationWithClassified |
      | user1Name | The Classified Domain | user2Name | user3Name | ClassifiedDomainConvo           |