Feature: Poll Messages

  @C856969 @C856970 @C856971 @C856972 @regression @pollmessages @landscape
  Scenario Outline: I want to receive confirmation/receipt that my response is stored
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1> to team <TeamName> with role Member
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And I sign in user <Member1> with fast login
    And I am signed in properly
    And User <TeamOwner> sends poll message "<PollMessageText>" with title "<PollMessageTitle>" and buttons "<Button1>,<Button2>" to conversation <Member1>
    When I open conversation "<TeamOwner>" in conversation list
    Then I see the poll message contains text "<PollMessageText>"
    And I see all the poll buttons are in unselected state
    When I tap poll button with the text "<Button1>"
    Then I see the poll button with the text "<Button1>" is Selected
    When User <TeamOwner> sends button action confirmation to user <Member1> on the latest poll in conversation <Member1> with button "<Button1>"
    Then I see the poll button with the text "<Button1>" is Confirmed
          #C856971 I should not see the unchosen buttons as selected
          #C856972 I should not have more than 1 poll button selected
    And I see the poll button with the text "<Button2>" is Unselected
    #C856970 I want to change my response
    When I tap poll button with the text "<Button2>"
    Then I see the poll button with the text "<Button2>" is Selected
    When User <TeamOwner> sends button action confirmation to user <Member1> on the latest poll in conversation <Member1> with button "<Button2>"
    Then I see the poll button with the text "<Button2>" is Confirmed
    And I see the poll button with the text "<Button1>" is Unselected

    Examples:
      | TeamOwner | Member1   | TeamName | PollMessageTitle | PollMessageText | Button1 | Button2 |
      | user1Name | user2Name | Mars     | title            | text            | Yes     | No      |

  @C856973 @C856974 @pollmessages @regression @landscape
  Scenario Outline: I want to add poll service to group conversation
    Given There is a team owner "<TeamOwner>" with team "<TeamName>"
    And User <TeamOwner> adds users <Member1>, <Member2> to team <TeamName> with role Member
    And User <TeamOwner> is me
    And User <TeamOwner> has conversation <ConversationName> with <Member1>,<Member2> in team <TeamName>
    And User <TeamOwner> enables <ServiceName> service for team <TeamName>
    And I sign in user <TeamOwner> with fast login
    And I see conversations list
    And I open conversation "<ConversationName>" in conversation list
    And I open group conversation details
    And I tap Add People button on Group Details page
    And I tap Services tab on Team Search UI page
    And I type "<ServiceName>" in Search UI input field
    And I see the service "<ServiceName>" exists in service search results
    And I tap on service "<ServiceName>" in service search result
    And I tap Add Service button on service detail page
    When I tap X button on Group Details page
    Then I see "You added Poll Bot" system message in the conversation view
    When I type the "<PollMessage>" message and send it
    And I see the poll button with the text "Yes" is Unselected
    And User <TeamOwner> disables <ServiceName> service for team <TeamName>
    And I scroll to the bottom of the conversation
    And I tap poll button with the text "Yes"
    #C856974 I should see an error if my response was not delievered
    Then I see error contains "<ErrorMsg>" under the poll button

    Examples:
      | TeamOwner | Member1   | Member2   | TeamName  | ConversationName | ServiceName  | PollMessage               | ErrorMsg                                 |
      | user1Name | user2Name | user3Name | Mars      | Unknown visitors | Poll Bot     | /poll "Fine?" "Yes" "No"  | Your answer can't be sent, please retry. |

