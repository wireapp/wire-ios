Feature: Technical Info

  # Note: WPB10813 only affects 3.113, so it isn't a known bug for 3.112
  @TC-8130 @col1 @BundSecurity @WPB10813
  Scenario: I can see my version details
    Given There is a team owner "user1Name" with team "Team Name"
    When I login to the default email verified backend as user1Name
    And I open settings screen
    And I open the Advanced Settings menu
