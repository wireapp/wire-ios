package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.*;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupAddPeoplePage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupConnectedParticipantProfilePage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupDetailsPage;
import com.wearezeta.auto.ios.pages.details_overlay.single.SinglePendingUserIncomingConnectionProfilePage;
import com.wearezeta.auto.ios.pages.linear_groupcreation.AddPeoplePage;
import com.wearezeta.auto.ios.pages.linear_groupcreation.NewGroupPage;
import com.wearezeta.auto.ios.pages.webview.WebViewPage;
import io.cucumber.java.en.When;

public class GroupSteps {
  IOSTestContext context;

  public GroupSteps(IOSTestContext context) {
    this.context = context;
  }

  private NewGroupPage getNewGroupPage() {
    return context.getPagesCollection().getPage(NewGroupPage.class);
  }

  private SearchUIPage getSearchUIPage() {
    return context.getPagesCollection()
        .getPage(SearchUIPage.class);
  }

  private GroupAddPeoplePage getGroupAddPeoplePage() {
    return context.getPagesCollection().getPage(GroupAddPeoplePage.class);
  }

  private GroupConnectedParticipantProfilePage getGroupParticipantProfilePage() {
    return context.getPagesCollection().getPage(GroupConnectedParticipantProfilePage.class);
  }

  private FileInspectionPage getFileInspectionPage()  {
    return context.getPagesCollection().getPage(FileInspectionPage.class);
  }

  private AddPeoplePage getAddPeoplePage()  {
    return context.getPagesCollection().getPage(AddPeoplePage.class);
  }

  private GroupDetailsPage getGroupDetailsPage() {
    return context.getPagesCollection().getPage(GroupDetailsPage.class);
  }

  private TeamSearchUIPage getTeamSearchUIPage() {
    return context.getPagesCollection().getPage(TeamSearchUIPage.class);
  }

  private ServiceDetailPage getServiceDetailPage() {
    return context.getPagesCollection().getPage(ServiceDetailPage.class);
  }

  private ConversationsListPage getConversationListPage() {
    return context.getPagesCollection().getPage(ConversationsListPage.class);
  }

  private SinglePendingUserIncomingConnectionProfilePage getSinglePendingUserIncomingConnectionProfilePage() {
    return context.getPagesCollection().getPage(SinglePendingUserIncomingConnectionProfilePage.class);
  }

  private WebViewPage getWebView() {
    return context.getPagesCollection().getPage(WebViewPage.class);
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
}
