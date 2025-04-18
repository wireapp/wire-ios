Feature: New Person Onboarding

  # TODO - Need to figure out why this one is failing because
  # it appears related to backend or kallium
  # Also figure out why changing username breaks it, appears to be related to common
  @flows @TC-8583
  Scenario Outline: New Employee Onboarding
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds user <Member1> to team <TeamName> with role Member
    And User <TeamOwner> adds user <Member2> to team <TeamName> with role Member and without unique username
    And User adds the following device: {"<TeamOwner>": [{"name": "<Device>"}]}
    And User <Member1> is me
    And User <TeamOwner> has conversation <ConversationTitle> with <Member1> in team <TeamName>
    When I login to Wire as <Member2>
    And I set the username to <Member2UniqueUsername>
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
#    And I select settings item Name
#    And I set "<NewName>" value to Name input field on Settings page
#    And I tap Return button on the keyboard
    And I tap on the settings back button
    And I tap Conversations button in bottom navigation bar
    And I open search screen
    And I type "<TeamOwner>" in Search UI input field
    And I tap on conversation <TeamOwner> in search result
    And I tap Start Conversation button on Single user profile page
    And I type the "Hey there, Everything is set up!" message and send it
    And I wait for 5 seconds
    # Change <Member2> back to <NewName> for next 3 lines
    And User <TeamOwner> marks the recent message as read in conversation <Member2> via device <Device>
#    And User <TeamOwner> sends message "Cool! Welcome to our Wire Team! We will send you the Wifi password" as reply to last message of conversation <Member2> via device <Device>
    And User <TeamOwner> sends ephemeral message "password" with timer 10 seconds to user <Member2>
    And I see last message in the conversation view is expected message password
#    And User <TeamOwner> creates invite link for conversation <ConversationTitle>
#    And User <TeamOwner> sends invite link for conversation <ConversationTitle> message to conversation <NewName>
#    And I tap at 50% of width and 50% of height of the recent message
#    And I tap Join in the app button in Safari
#    And I tap Open button on the alert
#    And I tap OK button on the alert
#    And I see conversation view page
#    And I open group conversation details
#    And I see conversation name "<ConversationTitle>" on Group Details page

    Examples:
      | Member1   | TeamOwner | TeamName  | Member2   | ConversationTitle | Member2UniqueUsername | Device  | NewName              |
      | user1Name | user3Name | SuperTeam | user2Name | The Official Chat | user2UniqueUsername   | device1 | My name without typo |
