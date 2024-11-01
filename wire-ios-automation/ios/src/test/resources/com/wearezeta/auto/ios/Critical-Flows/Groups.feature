Feature: Groups

  # Flow 2 - Team owner making an all team chat
  @flows @WPB6540
  Scenario Outline: Team owner making an all team chat (contains bug)
# Pre-conditions
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
# Team has at least 10 members + owner
    And User <TeamOwner> adds user <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6>,<Member7>,<Member8>,<Member9>,<Member10> to team <TeamName> with role Member
    And User <TeamOwner> is me
    # Failling here - code authentication required?
    And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
# Team owner logs in to their account
    And I sign in user <TeamOwner> with fast login
    And I accept alert if visible
# Team owner starts group creation flow
    And  I open search screen
    And I open create group screen
# Team Owner checks the conversation options
# TeamOwner disallows guests
  #  When I expand conversation options on New Group page
    Then I see Guests option on group creation view
    And I see Services option on group creation view
    And I verify the value of Allow Guests equals to "1" on New Group page
    And I switch Allow Guests toggle on New Group page
    And I verify the value of Allow Guests equals to "0" on New Group page
# TeamOwner names the conversation
    And I enter group name "<ConversationTitle>" on New Group page
# Team owner selects all team members
    And I tap Next button on New Group page
# Team owner creates the conversation
    And I type first 3 letters of name "<Member1>" in search input field on Add People page
    And I select search result item <Member1> on Add People page
    And I type first 3 letters of name "<Member2>" in search input field on Add People page
    And I select search result item <Member2> on Add People page
    And I type first 3 letters of name "<Member3>" in search input field on Add People page
    And I select search result item <Member3> on Add People page
    And I type first 3 letters of name "<Member4>" in search input field on Add People page
    And I select search result item <Member4> on Add People page
    And I type first 3 letters of name "<Member5>" in search input field on Add People page
    And I select search result item <Member5> on Add People page
    And I type first 3 letters of name "<Member6>" in search input field on Add People page
    And I select search result item <Member6> on Add People page
    And I type first 3 letters of name "<Member7>" in search input field on Add People page
    And I select search result item <Member7> on Add People page
    And I type first 3 letters of name "<Member8>" in search input field on Add People page
    And I select search result item <Member8> on Add People page
    And I type first 3 letters of name "<Member9>" in search input field on Add People page
    And I select search result item <Member9> on Add People page
    # Failing here due to request loop
    And I type first 3 letters of name "<Member10>" in search input field on Add People page
    And I select search result item <Member10> on Add People page
# Team owner exchanges messages
    And I tap Create button on Add People page
#    BUG Because guests are not allowed, none of the team members are actually added to the conversation??
#  https://wearezeta.atlassian.net/browse/WPB-6478
# New member joining the team & logs in
    And User <TeamOwner> adds user <Member11> to team <TeamName> with role Member
    And User adds the following device: {"<Member11>": [{"name": "Device3"}]}
# Team owner invites new member to conversation
    And I open group conversation details
    And I see Add People button on Group Details page
    When I tap Add People button on Group Details page
    And I type search query "<Member11>" on Group Add People page
    And I select search result item <Member11> on Group Add People page
    And I tap Add Participants button on Group Add People page
    And I tap X button on Group Details page
    And I see "You added <Member11>" system message in the conversation view
# Team owner sends welcome message with mention
    When I type the "<Message>" message
    When I tap Mention button from input tools
    And I type first 2 letters of name "<Member11>" in conversation input
    And I tap <Member11> in the suggested mentions list
    And I tap Send Message button in conversation view
    #TODO Uncomment once @WPB6540 fixed
#    Mentions are not "accessible" accordingto appium... https://wearezeta.atlassian.net/browse/WPB-6540
#    Then I see the last message in the conversation view contains mentions <Member11>
    Then I see last message in the conversation view contains expected message <Message>
# New member responds
    And User <Member11> sends message "<ThankYouMessage>" as reply to last message of conversation <ConversationTitle> via device Device3
    And I see last message in the conversation view is expected message <ThankYouMessage>
    And I see 1 reply in the conversation view

    Examples:
      | Member1   | TeamOwner | TeamName  | ThankYouMessage           | Member2   | ConversationTitle | Member3   | Member4   | Member5   | Member6   | Member7   | Member8   | Member9    | Member10   | Member11    | Message                         |
      | user1Name | user3Name | SuperTeam | Thank you! Hello everyone | user2Name | Official          | user4Name | user5Name | user6Name | user7Name | user8Name | user9Name | user10Name | user11Name | user12Name  | Welcome to our new team member  |


  @flows @07
  Scenario Outline: Enterprise User hosts a planning group
  #Users A is an enterprise user
    Given I allow camera access
    And I allow microphone access
    And There is a team owner "<UserA>" with team "<TeamName>"
    And TeamOwner "<UserA>" waits and enables conference calling feature for team <TeamName> via backdoor
    And User <UserA> adds user <UserD>,<UserE> to team <TeamName> with role Member
  #User A has group with UserD & UserE
    And User <UserA> has conversation <TeamName> with <UserD>, <UserE> in team <TeamName>
  #Users FreeB, FreeC are free users
    And There are personal account users <FreeB>, <FreeC>
    And User <FreeB> is Me
    And Users adds the following devices: {"Myself": [{"name": "<DeviceName>"}]}
    And User <UserA> is connected to <FreeB>, <FreeC>
    And User <UserA> is Me
  #User A creates a group with another User B.
    When I tap Login button on Welcome page
    When I login
    And I accept First Time overlay
    And I accept alert if visible
    And  I open search screen
    And I open create group screen
    And I enter group name "<GroupName>" on New Group page
    And I tap Next button on New Group page
    And I select search result item <FreeB> on Group Add People page
    And I select search result item <UserD> on Group Add People page
    And I select search result item <UserE> on Group Add People page
    And I tap Done button on Invite People page
  #User A makes User B an admin
    When I open group conversation details
    And I select participant <FreeB> on Group Details page
    And I tap Admin toggle on Group participant profile page
    And I tap Back button on Group participant profile page
  #User A adds User C to group
    And I tap Add People button on Group Details page
    And I select search result item <FreeC> on Add People page
    And I tap Add Participants button on Group Add People page
    And I tap X button on Group Details page
  #User C sends a message to group
    Given User <FreeC> sends 1 default messages to conversation <GroupName>
  #User B reads the message
    And User <FreeB> marks the recent message as read in conversation <GroupName> via device <DeviceName>
  #User A is unable to see that User B read the message
    Then I do not see the delivery status in message toolbox
    #User A pings the group
    And I tap ellipsis button from input tools
    And I tap Ping button from input tools
    And I accept alert
  #User A reacts to User C's message
    When I long tap default message in conversation view
    And I tap on ❤️ reaction in quick reactions
  #    User D member sends a link to the group chat
    And User <UserE> sends link preview for "https://www.wire.com/" to conversation <GroupName>
  #User A sends a drawing
    When I tap Sketch button on Picture Preview page
    And I draw a random sketch
    And I tap Send button on Sketch page
  #User A sends a location
    And I tap ellipsis button from input tools
    And I tap Share Location button from input tools
    And I accept alert if visible
    And I tap Send location button from map view
  #User A sends a voice message
    And I tap Audio Message button from input tools
    And I accept microphone access alert on real device
    And I wait for 5 seconds
    And I tap Start Recording button on Voice Filters overlay
    And I wait for 1 second
    And I tap Stop Recording button on Voice Filters overlay
    When I tap <ButtonsCount> random effect buttons on Voice Filters overlay
    And I tap Confirm button on Voice Filters overlay
  #UserA starts an audio call
    And I accept alert if visible
    And <FreeB> starts instance using chrome
    And <FreeB> accepts next incoming call automatically
    And I tap Audio Call button
    And I tap call button on start call alert
  #User A hangs up
    And I tap Leave button on Calling overlay
    Then I see conversation view page

    Examples:
      | UserA     | FreeB     | FreeC     | UserD      | UserE      | GroupName | DeviceName | TeamName | GiphyTag | ButtonsCount |
      | user1Name | user2Name | user3Name | user4Name  | user5Name  | GroupName | device     | TeamName | gif      | 4            |
