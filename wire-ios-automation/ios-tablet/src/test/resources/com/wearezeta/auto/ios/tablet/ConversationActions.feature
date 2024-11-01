Feature: Conversation Actions

  @C747587 @unstable @conversationactions @landscape
  Scenario Outline: I want to see conversation actions as team member in team group - tablet
    Given There are personal account users <Personal>,<NonConnected>
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Partner> to team <TeamName> with role Partner
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And There is a team owner "<MemberOfOtherTeam>" with team "<TeamName2>"
    And User <Member1> is connected to <Personal>
    And User <Member1> is connected to <MemberOfOtherTeam>
    And User <TeamOwner> is connected to <Personal>,<MemberOfOtherTeam>,<NonConnected>
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Partner>,<Personal>,<MemberOfOtherTeam>,<NonConnected> in team <TeamName>
    And Team user <TeamOwner> allows guests in conversation <ConversationName>
    And Team user <TeamOwner> invites wireless user <WirelessGuest> to conversation <ConversationName>
    And User <TeamOwner> changes users <Member1> to role Admin for conversation "<ConversationName>"
    And User <Member1> is me
    And I tap Login button on Welcome page
    And I sign in user <Member1> with email
    And I accept First Time overlay
    And I open group conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I swipe up on Group Details page
        # Look at another team member role
    When I select participant <TeamOwner> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Remove From Group… conversation action button
    And I do not see Block… conversation action button
      # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a partner role
    When I select participant <Partner> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Remove From Group… conversation action button
    And I do not see Block… conversation action button
      # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(personal) role
    When I select participant <Personal> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Block… conversation action button
    And I see Remove From Group… conversation action button
      # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(Wireless) role
    When I select participant <WirelessGuest> on Group Details page
    Then I do not see left action button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Remove From Group… conversation action button
      # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(Team) role
    When I select participant <MemberOfOtherTeam> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Block… conversation action button
    And I see Remove From Group… conversation action button
      # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(non-connected)
    When I select participant <NonConnected> on Group Details page
    Then I see Connect button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I do not see Block… conversation action button
    And I see Remove From Group… conversation action button

    Examples:
      | Member1   | TeamName | TeamOwner | Partner   | Personal  | MemberOfOtherTeam | TeamName2 | WirelessGuest | NonConnected | ConversationName |
      | user1Name | Red      | user2Name | user3Name | user4Name | user5Name         | Blue      | user6Name     | user7Name    | Colorful         |

  @C747588 @unstable @conversationactions @landscape
  Scenario Outline: I want to see conversation actions as partner in team group
    Given There are personal account users <Personal>,<NonConnected>
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Partner1>,<Partner2> to team <TeamName> with role Partner
    And There is a team owner "<MemberOfOtherTeam>" with team "<TeamName2>"
    And User <Partner1> is me
    And User Myself is connected to <Personal>
    And User Myself is connected to <MemberOfOtherTeam>
    And User <TeamOwner> is connected to <Personal>,<MemberOfOtherTeam>,<NonConnected>
    And User <TeamOwner> has conversation <ConversationName> with <Partner1>,<Partner2>,<Personal>,<MemberOfOtherTeam>,<NonConnected> in team <TeamName>
    And Team user <TeamOwner> allows guests in conversation <ConversationName>
    And Team user <TeamOwner> invites wireless user <WirelessGuest> to conversation <ConversationName>
    And I tap Login button on Welcome page
    And I sign in user <Partner1> with email
    And I accept First Time overlay
    And I open group conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I swipe up on Group Details page
        # Look at another team member role
    When I select participant <TeamOwner> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I do not see More Actions button on Group participant profile page
    And I tap Back button on Group participant profile page
        # Look at a partner role
    When I select participant <Partner2> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I do not see More Actions button on Group participant profile page
    And I tap Back button on Group participant profile page
        # Look at a Guest(connected-personal) role
    When I select participant <Personal> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I do not see Remove From Group… conversation action button
    And I see Block… conversation action button
      # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(Wireless) role
    When I select participant <WirelessGuest> on Group Details page
    Then I do not see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Remove From Group… conversation action button
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(connected-team) role
    When I select participant <MemberOfOtherTeam> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I do not see Remove From Group… conversation action button
    And I see Block… conversation action button
        # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(non-connected) role
    When I select participant <NonConnected> on Group Details page
    Then I see Connect button on Group participant profile page
    And I do not see More Actions button on Group participant profile page

    Examples:
      | Partner1  | TeamName | TeamOwner | Partner2  | Personal  | MemberOfOtherTeam | TeamName2 | WirelessGuest | NonConnected | ConversationName |
      | user1Name | Red      | user2Name | user3Name | user4Name | user5Name         | Blue      | user6Name     | user7Name    | Knock-knock      |

  @C747589 @regression @conversationactions @landscape
  Scenario Outline: I want to see conversation actions as guest (personal account) in team group
    Given There are personal account users <Personal1>,<Personal2>,<NonConnected>
    And There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Partner> to team <TeamName> with role Partner
    And There is a team owner "<MemberOfOtherTeam>" with team "<TeamName2>"
    And User <Personal1> is me
    And User Myself is connected to <Personal2>,<TeamOwner>,<Partner>,<MemberOfOtherTeam>
    And User <TeamOwner> is connected to <Personal2>,<MemberOfOtherTeam>,<NonConnected>
    And User <TeamOwner> has conversation <ConversationName> with <Personal1>,<Partner>,<Personal2>,<MemberOfOtherTeam>,<NonConnected> in team <TeamName>
    And Team user <TeamOwner> allows guests in conversation <ConversationName>
    And Team user <TeamOwner> invites wireless user <WirelessGuest> to conversation <ConversationName>
    And I tap Login button on Welcome page
    And I sign in user <Personal1> with email
    And I accept First Time overlay
    And I accept Help us make Wire better popup
    And I open group conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I swipe up on Group Details page
        # Look at connected-team member role
    When I select participant <TeamOwner> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Block… conversation action button
    And I do not see Remove From Group… conversation action button
        # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a connected-partner role
    When I select participant <Partner> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I see Block… conversation action button
    And I do not see Remove From Group… conversation action button
        # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(connected-personal) role
    When I select participant <Personal2> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I do not see Remove From Group… conversation action button
    And I see Block… conversation action button
        # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(Wireless) role
    When I select participant <WirelessGuest> on Group Details page
    Then I do not see left action button on Group participant profile page
    And I do not see More Actions button on Group participant profile page
    And I tap Back button on Group participant profile page
        # Look at a Guest(connected-team) role
    When I select participant <MemberOfOtherTeam> on Group Details page
    Then I see Open Conversation button on Group participant profile page
    And I see More Actions button on Group participant profile page
    And I tap Open Menu button on Group participant profile page
    And I do not see Remove From Group… conversation action button
    And I see Block… conversation action button
        # This will dismiss the actions sheet
    And I dismiss popover on iPad
    And I tap Back button on Group participant profile page
        # Look at a Guest(non-connected) role
    When I select participant <NonConnected> on Group Details page
    Then I see Connect button on Group participant profile page
    And I do not see More Actions button on Group participant profile page

    Examples:
      | Personal1 | TeamName | TeamOwner | Partner   | Personal2 | MemberOfOtherTeam | TeamName2 | WirelessGuest | NonConnected | ConversationName |
      | user1Name | Red      | user2Name | user3Name | user4Name | user5Name         | Blue      | user6Name     | user7Name    | Rainbow Roll     |
