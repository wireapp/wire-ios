package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.common.usrmgmt.ClientUsersManager;
import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.SearchUIPage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupAddPeoplePage;
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
      String name = alias;
      name = context.getUsersManager()
          .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.NAME_ALIAS);
      name = context.getUsersManager()
          .replaceAliasesOccurrences(name, ClientUsersManager.FindBy.UNIQUE_USERNAME_ALIAS);

      if (name.length() > count) {
        getGroupAddPeoplePage().typeSearchQuery(name.substring(0, count));
      } else {
        throw new IllegalArgumentException(String.format("Name is only %s chars length. Put in step a less value",
            name.length()));
      }

      getAddPeoplePage().selectItem(name);
    }

    getAddPeoplePage().tapCreateButton();
  }
}
