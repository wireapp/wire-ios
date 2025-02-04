package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import io.cucumber.java.en.And;
import io.cucumber.java.en.When;

public class GroupSteps extends IOSSteps {

  public GroupSteps(IOSTestContext context) {
    super(context);
  }

  @When("^I create new group \"(.*)\"$")
  public void iCreateNewGroup(String groupName) {
    getSearchUIPage().iOpenCreateGroupScreen();
    getNewGroupPage().enterGroupName(groupName);
    getNewGroupPage().tapNextButton();
  }

  @When("I add members (.*) to new group via search")
  public void iAddMembersToNewGroupViaSearch(String members) {
    String[] aliases = members.split(",");

    for (String alias : aliases) {
      String name = alias.strip();
      name = context.getUsersManager()
          .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
      name = context.getUsersManager()
          .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);

      getGroupAddPeoplePage().searchAndAdd(name);
    }

    getAddPeoplePage().tapCreateButton();
  }

  @When("I add members (.*) to existing group via search")
  public void iAddMembersToExistingGroupViaSearch(String members) {
    String[] aliases = members.split(",");
    getGroupDetailsPage().tapAddPeopleButton();

    for (String alias : aliases) {
      String name = alias.strip();
      name = context.getUsersManager()
          .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
      name = context.getUsersManager()
          .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);

      getGroupAddPeoplePage().searchAndAdd(name);
    }

    getGroupAddPeoplePage().tapAddButton();
    getGroupDetailsPage().tapXButton();
  }

  @When("I add service (.*) to group")
  public void iAddService(String serviceName) {
    getGroupDetailsPage().tapAddPeopleButton();
    getTeamSearchUIPage().tapTeamSearchUITab();

    getGroupAddPeoplePage().searchAndAdd(serviceName);

    getServiceDetailPage().addService();
    getGroupDetailsPage().tapXButton();
  }

  @When("^I remove (.*) from group$")
  public void removeFromGroup(String name) {
    name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);

    getGroupDetailsPage().selectParticipant(name);
    getGroupParticipantProfilePage().tapRemoveFromConversationButton();
    getGroupParticipantProfilePage().confirmRemove();
  }

  @When("I accept connection request from (.*)")
  public void iAcceptConnectionRequestFrom(String name) {
    name = context.getUsersManager().replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);

    getConversationListPage().openConnectionRequest();
    getSinglePendingUserIncomingConnectionProfilePage().tapConnect();
  }

  @When("I share the current file in conversation (.*)")
  public void iShareCurrentFile(String conversationName) {
    getFileInspectionPage().tapShareButton();
    getWebView().tapMoreButonShareExt();
    getWebView().tapWireInShareExt();
    getWebView().tapChooseInShareExt();
    conversationName = context.getUsersManager()
        .replaceAliasesOccurrences(conversationName, ClientUsersManager.FindBy.NAME_ALIAS);
    getWebView().selectConversationInShareExt(conversationName);
    getWebView().tapSendButtonShareExt();
    getFileInspectionPage().tapDoneButton();
  }

  @When("I copy the group invite link")
  public void iCopyTheGroupInviteLink() {
    getConversationViewPage().openConversationDetails();
    getGroupDetailsPage().openGuestOptions();
    getGuestOptionsPage().createLinkWithoutPassword();
    getGuestOptionsPage().copyLink();
  }

  @When("I send what is in my pasteboard")
  public void iSendWhatIsInMyPasteboard() {
    getConversationViewPage().sendMessage(context.getDriver().getClipboardText());
  }
}
