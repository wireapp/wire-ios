package com.wearezeta.auto.ios.pages.search;

import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.common.misc.Timedelta;

public class GroupParticipantsList extends BaseSearchableItemsList {
    private static final String classChainStrViewRoot = "**/XCUIElementTypeCollectionView[`name == 'group_details.list'`]";

    public GroupParticipantsList(WebDriver driver) {
        super(driver, classChainStrViewRoot);
    }

    public void selectParticipant(String name) {
        selectItem(nameStrParticipantCell, name);
    }

    public int getPeopleCount() {
        return selectVisibleElements(nameParticipantCell, Timedelta.ofSeconds(3)).size();
    }

    public int getServicesCount() {
        return selectVisibleElements(nameServiceCellName, Timedelta.ofSeconds(3)).size();
    }

    @Override
    public boolean isUniqueUserNameLabelVisibleFor(String name) {
        return super.isUniqueUserNameLabelVisibleFor(nameStrParticipantCell, name);
    }

    @Override
    public boolean isUniqueUserNameLabelInvisibleFor(String name) {
        return super.isUniqueUserNameLabelInvisibleFor(nameStrParticipantCell, name);
    }

    public boolean isParticipantVisible(String name) {
        return super.isItemVisible(nameStrParticipantCell, name);
    }

    public boolean isParticipantInvisible(String name) {
        return super.isItemInvisible(nameStrParticipantCell, name);
    }

    @Override
    public boolean isGuestLabelVisibleFor(String name) {
        return super.isGuestLabelVisibleFor(nameStrParticipantCell, name);
    }

    @Override
    public boolean isGuestLabelInvisibleFor(String name) {
        return super.isGuestLabelInvisibleFor(nameStrParticipantCell, name);
    }

    public boolean isExternalIconVisibleFor(String name) {
        return super.isExternalIconVisibleFor(nameStrParticipantCell, name);
    }
}
