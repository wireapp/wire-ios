Feature: Images

  @TC-4983 @TC-4984 @TC-4982 @TC-4987 @TC-4985 @TC-4986 @col1
  Scenario Outline: I want to see the option to draw an image from within the app
    Given There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}, {}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    And All other versions of Wire are uninstalled
    When I login to the default email verified backend as <Member1>
    Then I am signed in properly
    When I open conversation "<TeamOwner>" in conversation list
    Then I see Sketch button in input tools palette
    # I should not see the gallery option while drawing an image - TC-4984
    When I tap Sketch button from input tools
    Then I do not see phone gallery button in a draw sketch view
    # I want to send drawings with the drawing feature within the app - TC-4982
    When I draw a random sketch
    And I tap Send button on Sketch page
    Then I see 1 photo in the conversation view
    When User <TeamOwner> sends delivery confirmation for the recent message in Myself conversation
    Then I see "<DeliveredLabel>" on the message toolbox in conversation view
    When I long tap on image in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I do not see Copy on edit menu
    And I tap on screen to enable video calling overlay
    # I should not be able to download the drawings  - TC-4987
    When I tap on image in conversation view
    Then I see Full Screen Page opened
    And I do not see Copy on edit menu
    And I do not see Download on edit menu

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName     | GroupConversationName | DeliveredLabel |
      | user1Name | user2Name | user3Name | File sharing | FileSharing           | Delivered      |

  @C1151106 @C1151107 @C1151108 @C1151109 @C1151084 @C1151085 @C1151086 @real
  Scenario Outline: I want to see the option to send an image using camera roll from within the app
    Given I allow access to all photos
    And I allow camera access
    And There is a team owner "<TeamOwner>" with team "<TeamName>" on column-1 backend
    And User <TeamOwner> adds users <Member1>,<Member2> to team <TeamName> with role Member
    And User <TeamOwner> has conversation <GroupConversationName> with <Member1>,<Member2> in team <TeamName>
    And Users of team owned by <TeamOwner> adds the following 2FA devices: {"<TeamOwner>": [{"name": "<DeviceName>"}, {}]}
    And User <Member1> is me
    And User Myself has 1:1 conversation with <TeamOwner> in team <TeamName>
    And User Myself has 1:1 conversation with <Member2> in team <TeamName>
    When I login to the default email verified backend as <Member1>
    Then I am signed in properly
    When I open conversation "<TeamOwner>" in conversation list
    Then I see Add Picture button in input tools palette
    And I do not see first item from Keyboard Gallery
    # I want to send an image using camera roll from within the app - C1151107
    When I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I tap Fullscreen Camera button on Keyboard Gallery overlay
    And I accept alert if visible
    And I tap Take Photo button on Camera page
    And I tap Use Photo button on Picture preview page
    And I accept alert if visible
    Then I see 1 photo in the conversation view
    When I long tap on audio message placeholder in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I see Share on edit menu
    And I do not see Copy on edit menu
    # I should not be able to download the received images - C1151108
    When User <TeamOwner> sends 1 image file <Picture> to conversation Myself
    Then I see 1 photo in the conversation view
    When I long tap on audio message placeholder in conversation view
    Then I do not see Download on edit menu
    And I do not see Save on edit menu
    And I do not see Copy on edit menu
    # I want to receive and open images within the app - C1151109
    When I tap on image in conversation view
    And I see Full Screen Page opened
    Then I do not see Copy on edit menu
    And I do not see Download on edit menu
    # I want to forward the received image to another user in 1:1 - C1151087
    When I long tap on image in conversation view
    And I tap on Share on edit menu
    And I select <Member2> conversation on Forward page
    And I tap Send button on Forward page
    And I long tap on image in conversation view
    And I tap on Share on edit menu
    And I select <GroupConversationName> conversation on Forward page
    And I tap Send button on Forward page
    And I navigate back to conversations list
    And I open conversation "<Member2>" in conversation list
    Then I see 1 photo in the conversation view
    # I want to forward the received image to another user in a group conversation - C1151088
    When I navigate back to conversations list
    And I open conversation "<GroupConversationName>" in conversation list
    Then I see 1 photo in the conversation view

    Examples:
      | Member1   | Member2   | TeamOwner | TeamName     | DeviceName | GroupConversationName | Picture     |
      | user1Name | user2Name | user3Name | File sharing | device1    | FileSharing           | testing.jpg |
