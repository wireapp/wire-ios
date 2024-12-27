Feature: Group Management


    @flows @WPB6540
    Scenario Outline: Team owner making an all team chat (contains bug)
        Given There is a team owner "<TeamOwner>" with team "<TeamName>"
        Given I allow microphone access
        And User <TeamOwner> adds user <Member1>,<Member2>,<Member3>,<Member4>,<Member5>,<Member6>,<Member7>,<Member8>,<Member9>,<Member10> to team <TeamName> with role Member
        And User <TeamOwner> is me
        And User adds the following device: {"<Member1>": [{"name": "<device1>"}], "<Member2>": [{"name": "<device2>"}]}
        And I sign in user <TeamOwner> with fast login
        And I accept alert if visible
        And  I open search screen
        And I open create group screen
        Then I see Guests option on group creation view
        And I see Services option on group creation view
        And I verify the value of Allow Guests equals to "1" on New Group page
        And I switch Allow Guests toggle on New Group page
        And I verify the value of Allow Guests equals to "0" on New Group page
        And I enter group name "<ConversationTitle>" on New Group page
        And I tap Next button on New Group page
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
        And I type first 3 letters of name "<Member10>" in search input field on Add People page
        And I select search result item <Member10> on Add People page
        And I tap Create button on Add People page
        And User <TeamOwner> adds user <Member11> to team <TeamName> with role Member
        And User adds the following device: {"<Member11>": [{"name": "Device3"}]}
        And I open group conversation details
        And I see Add People button on Group Details page
        When I tap Add People button on Group Details page
        And I type search query "<Member11>" on Group Add People page
        And I select search result item <Member11> on Group Add People page
        And I tap Add Participants button on Group Add People page
        And I tap X button on Group Details page
        And I see "You added <Member11>" system message in the conversation view
        When I type the "<Message>" message
        When I tap Mention button from input tools
        And I type first 2 letters of name "<Member11>" in conversation input
        And I tap <Member11> in the suggested mentions list
        And I tap Send Message button in conversation view
        Then I see last message in the conversation view contains expected message <Message>
        And User <Member11> sends message "<ThankYouMessage>" as reply to last message of conversation <ConversationTitle> via device Device3
        And I see last message in the conversation view is expected message <ThankYouMessage>
        And I see 1 reply in the conversation view
        When I tap Sketch button on Picture Preview page
        And I draw a random sketch
        And I tap Send button on Sketch page
        And I tap Audio Message button from input tools
        And I accept microphone access alert on real device
        And I tap Start Recording button on Voice Filters overlay
        And I wait for 1 second
        And I tap Stop Recording button on Voice Filters overlay
        When I tap <ButtonsCount> random effect buttons on Voice Filters overlay
        And I tap Confirm button on Voice Filters overlay
        Then I tap Play audio message button
        Then I tap Hourglass button in conversation view
        And  I set self deleting message expiration timer to 10 seconds on conversation view
        And I type the default message and send it
        And I wait for 10 seconds
        Then I see 0 default message in the conversation view
        And I navigate back to conversations list
        When I long tap conversation '<ConversationTitle>' in conversation list
        Then I choose Leave Group from conversation list context menu
        And I choose Leave and Clear in the dialog
        And  I open search screen
        Then I type "<ConversationTitle>" in cleared Search UI input field
        And I see the conversation "<ConversationTitle>" does not exists in Search results


        Examples:
            | Member1   | TeamOwner | TeamName  | ThankYouMessage           | Member2   | ConversationTitle | Member3   | Member4   | Member5   | Member6   | Member7   | Member8   | Member9    | Member10   | Member11    | Message                         | ButtonsCount |
            | user1Name | user3Name | SuperTeam | Thank you! Hello everyone | user2Name | Official          | user4Name | user5Name | user6Name | user7Name | user8Name | user9Name | user10Name | user11Name | user12Name  | Welcome to our new team member  | 4            |