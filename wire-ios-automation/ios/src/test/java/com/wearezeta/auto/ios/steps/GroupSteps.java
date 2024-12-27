package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.SearchUIPage;
import com.wearezeta.auto.ios.pages.ServiceDetailPage;
import com.wearezeta.auto.ios.pages.TeamSearchUIPage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupAddPeoplePage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupDetailsPage;
import com.wearezeta.auto.ios.pages.linear_groupcreation.AddPeoplePage;
import com.wearezeta.auto.ios.pages.linear_groupcreation.NewGroupPage;
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

  @When("^I create new group \"(.*)\"$")
  public void iCreateNewGroup(String groupName) {
    getSearchUIPage().iOpenCreateGroupScreen();
    getNewGroupPage().enterGroupName(groupName);
    getNewGroupPage().tapNextButton();
  }

  @When("I add members (.*) to new group via search")
  public void iAddMembersToNewGroupViaSearch(String members) {
    String[] aliases = members.split(",");
    int count = 3;

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

  @When("I add service (.*) to group")
  public void iAddService(String serviceName) {
    getGroupDetailsPage().tapAddPeopleButton();
    getTeamSearchUIPage().tapTeamSearchUITab();

    getGroupAddPeoplePage().searchAndAdd(serviceName);

    getServiceDetailPage().addService();
    getGroupDetailsPage().tapXButton();
  }
}
