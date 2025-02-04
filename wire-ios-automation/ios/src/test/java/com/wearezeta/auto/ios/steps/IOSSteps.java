package com.wearezeta.auto.ios.steps;

import com.wearezeta.auto.ios.common.IOSTestContext;
import com.wearezeta.auto.ios.pages.*;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupAddPeoplePage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupConnectedParticipantProfilePage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GroupDetailsPage;
import com.wearezeta.auto.ios.pages.details_overlay.group.GuestOptionsPage;
import com.wearezeta.auto.ios.pages.details_overlay.single.SinglePendingUserIncomingConnectionProfilePage;
import com.wearezeta.auto.ios.pages.linear_groupcreation.AddPeoplePage;
import com.wearezeta.auto.ios.pages.linear_groupcreation.NewGroupPage;
import com.wearezeta.auto.ios.pages.webview.WebViewPage;

public class IOSSteps {
  IOSTestContext context;

  public IOSSteps(IOSTestContext context) {
    this.context = context;
  }

  NewGroupPage getNewGroupPage() {
    return context.getPagesCollection().getPage(NewGroupPage.class);
  }

  SearchUIPage getSearchUIPage() {
    return context.getPagesCollection()
        .getPage(SearchUIPage.class);
  }

  GroupAddPeoplePage getGroupAddPeoplePage() {
    return context.getPagesCollection().getPage(GroupAddPeoplePage.class);
  }

  GroupConnectedParticipantProfilePage getGroupParticipantProfilePage() {
    return context.getPagesCollection().getPage(GroupConnectedParticipantProfilePage.class);
  }

  FileInspectionPage getFileInspectionPage()  {
    return context.getPagesCollection().getPage(FileInspectionPage.class);
  }

  AddPeoplePage getAddPeoplePage()  {
    return context.getPagesCollection().getPage(AddPeoplePage.class);
  }

  GroupDetailsPage getGroupDetailsPage() {
    return context.getPagesCollection().getPage(GroupDetailsPage.class);
  }

  TeamSearchUIPage getTeamSearchUIPage() {
    return context.getPagesCollection().getPage(TeamSearchUIPage.class);
  }

  ConversationViewPage getConversationViewPage() {
    return context.getPagesCollection().getPage(ConversationViewPage.class);
  }

  ServiceDetailPage getServiceDetailPage() {
    return context.getPagesCollection().getPage(ServiceDetailPage.class);
  }

  ConversationsListPage getConversationListPage() {
    return context.getPagesCollection().getPage(ConversationsListPage.class);
  }

  SinglePendingUserIncomingConnectionProfilePage getSinglePendingUserIncomingConnectionProfilePage() {
    return context.getPagesCollection().getPage(SinglePendingUserIncomingConnectionProfilePage.class);
  }

  GuestOptionsPage getGuestOptionsPage() {
    return context.getPagesCollection().getPage(GuestOptionsPage.class);
  }

  WebViewPage getWebView() {
    return context.getPagesCollection().getPage(WebViewPage.class);
  }
}
