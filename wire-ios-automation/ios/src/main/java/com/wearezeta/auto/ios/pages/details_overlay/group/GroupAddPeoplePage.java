package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.ios.pages.search.GroupParticipantsSearchList;
import org.openqa.selenium.WebElement;

public class GroupAddPeoplePage extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "type == 'XCUIElementTypeButton' AND name == 'Add Participants'")
    private WebElement addPeopleButton;

    @iOSXCUITFindBy(accessibility = "close")
    private WebElement exitAddPeopleButton;

    private final GroupParticipantsSearchList participantsSearchList;

    public GroupAddPeoplePage(WebDriver driver) {
        super(driver);
        this.participantsSearchList = new GroupParticipantsSearchList(driver);
    }

    public void tapCloseButton() {
        exitAddPeopleButton.click();
    }

    public void tapAddButton() {
        addPeopleButton.click();
    }

    public void typeSearchQuery(String text) {
        participantsSearchList.typeSearchQuery(text);
    }

    public void selectItem(String name) {
        participantsSearchList.selectItem(name);
    }

    public void searchAndAdd(String name) {
        searchAndAdd(name, 3);
    }

    public void searchAndAdd(String name, int count) {
        if (name.length() > count) {
            typeSearchQuery(name.substring(0, count));
        } else {
            throw new IllegalArgumentException(String.format("Name is only %s chars length. Put in step a less value",
                name.length()));
        }

        selectItem(name);
    }

    public boolean isItemVisible(String name) {
        return participantsSearchList.isItemVisible(name);
    }

    public boolean isItemInvisible(String name) {
        return participantsSearchList.isItemInvisible(name);
    }

    public boolean waitUntilResultsLabelIsVisible(String msg) {
        return participantsSearchList.waitUntilResultsLabelIsVisible(msg);
    }
}
