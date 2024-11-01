Feature: New Person Onboarding

  @flows @01
  Scenario Outline: New Employee Onboarding
# PreReqs
# Team exists
# New employee invited to team
# Team has group conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> adds user <Member2> to team <TeamName> with role Member and without unique username
    And User adds the following device: {"<TeamOwner>": [{"name": "<Device>"}]}
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationTitle> with <Member1> in team <TeamName>
    And I see Welcome page
    And I tap Login button on Welcome page
#   # New employee logs in
    And I enter login <Member2Email> on Login page
    And I enter password <Password> on Login page
    And I tap Login button on Login page
    And I accept First Time overlay
    # New employee sets up their profile: name, picture, read receipts, color
    And I set the username to <Member2UniqueUsername>
    #And I wait for 3 seconds
    And I accept alert if visible
    And I open settings screen
    And I select settings item Account
    And I select settings item Picture
    When I tap Choose from library button on change profile pop up
    And I select a picture from Camera Roll
    And I tap Confirm button on Picture preview page
    And I wait for 3 seconds
    And I select settings item Color
    And I select color Purple on Profile Color page
    And  I tap on the account back button
    And I toggle send read receipts on account page
    And I select settings item Name
    And I set "<NewName>" value to Name input field on Settings page
    And I tap Return button on the keyboard
    And I tap on the settings back button
    And I tap Conversations button in bottom navigation bar
  # Search and contact team lead
    And I open search screen
    And I type "<TeamOwner>" in Search UI input field
    And I tap on conversation <TeamOwner> in search result
    And I tap Start Conversation button on Single user profile page
    And I type the "Hey there, Everything is set up!" message and send it
    And I wait for 5 seconds
    And User <TeamOwner> marks the recent message as read in conversation <NewName> via device <Device>
    And User <TeamOwner> sends message "Cool! Welcome to our Wire Team! We will send you the Wifi password" as reply to last message of conversation <NewName> via device <Device>
# Team lead sends invite link to the team conversation
    And User <TeamOwner> sends ephemeral message "password" with timer 10 seconds to user <NewName>
    And I see last message in the conversation view is expected message password
# Team lead sends invite link to the team conversation
    And User <TeamOwner> creates invite link for conversation <ConversationTitle>
    And User <TeamOwner> sends invite link for conversation <ConversationTitle> message to conversation <NewName>
# New employee able to follow link
    And I tap at 50% of width and 50% of height of the recent message
    And I tap Join in the app button in Safari
    And I tap Open button on the alert
    And I tap OK button on the alert
    And I see conversation view page
    And I open group conversation details
    And I see conversation name "<ConversationTitle>" on Group Details page

    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | ConversationTitle | Member2Email  | Password      | Member2UniqueUsername | Device  | NewName              |
      | user1Name | user3Name | SuperTeam | user2Name | The Official Chat | user2Email    | user2Password | user2UniqueUsername   | device1 | My name without typo |
