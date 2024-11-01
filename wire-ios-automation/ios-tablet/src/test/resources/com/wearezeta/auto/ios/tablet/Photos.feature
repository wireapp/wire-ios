Feature: Photos

  @C2629 @regression @landscape
  Scenario Outline: I want to verify you can see conversation images in fullscreen [LANDSCAPE]
    Given I allow camera access
    And I allow access to all photos
    And There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    When I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I select the first item from Keyboard Gallery
    And I tap Confirm button on Picture preview page
    And I tap on image in conversation view
    And I see Full Screen Page opened
    And I tap X button on fullscreen image
    Then I see 1 photo in the conversation view

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2630 @regression @landscape
  Scenario Outline: I want to rotate image in fullscreen mode [LANDSCAPE]
    Given I allow access to all photos
    And I allow camera access
    And There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And I sign in user <Name> with fast login
    And I open conversation "<Contact>" in conversation list
    When I tap Add Picture button from input tools
    And I accept camera access alert on real device
    And I accept access to all photos on real device
    And I select the first item from Keyboard Gallery
    And I tap Confirm button on Picture preview page
    And I tap on image in conversation view
    And I see Full Screen Page opened
    And I rotate UI to portrait
    Then I see Full Screen Page opened

    Examples:
      | Name      | Contact   |
      | user1Name | user2Name |

  @C2631 @regression @landscape
  Scenario Outline: I want to verify downloading images in fullscreen [LANDSCAPE]
    Given I allow access to all photos
    And There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 image file <Picture> to conversation Myself
    And I open conversation "<Contact>" in conversation list
    # Wait for the image to be loaded
    And I wait for 5 seconds
    When I long tap on image in conversation view
    Then I see Save on edit menu
    When I tap on Save on edit menu
    And I accept access to all photos on real device
    Then I do not see Save on edit menu
    And I see 1 photo in the conversation view

    Examples:
      | Name      | Contact   | Picture     |
      | user1Name | user2Name | testing.jpg |

  @C2624 @regression @rc @landscape
  Scenario Outline: I want to verify sending GIF format pic [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 image file <GifPicture> to conversation Myself
    And I open conversation "<Contact>" in conversation list
    # Wait for the picture to be loaded
    When I wait for 5 seconds
    Then I see the picture in the conversation view is animated
    When I tap on image in conversation view
      # Wait for animation
    And I wait for 5 seconds
    Then I see the picture on image fullscreen page is animated

    Examples:
      | Name      | Contact   | GifPicture   |
      | user1Name | user2Name | animated.gif |

  @C2587 @regression @landscape
  Scenario Outline: I want to verify possibility to copy image in the conversation view [LANDSCAPE]
    Given There are 2 users where <Name> is me
    And User Myself is connected to <Contact>
    And User adds the following device: {"<Contact>": [{}]}
    And I sign in user <Name> with fast login
    And I am signed in properly
    And User <Contact> sends 1 image file <Picture> to conversation Myself
    And I open conversation "<Contact>" in conversation list
    And I see 1 photo in the conversation view
    # Wait for polka dots to disappear
    And I wait for 7 seconds
    When I long tap on image in conversation view
    And I tap on Copy on edit menu
    And I tap on text input
    And I long tap on text input
    And I tap on Paste on edit menu
    And I tap OK button on paste dialog
      # Wait for animation
    And I wait for 2 seconds
    Then I see 2 photos in the conversation view

    Examples:
      | Name      | Contact   | Picture     |
      | user1Name | user2Name | testing.jpg |