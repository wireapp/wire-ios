package com.wearezeta.auto.ios.pages.linear_groupcreation;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import com.wearezeta.auto.ios.pages.IOSPage;
import com.wearezeta.auto.ios.pages.search.GroupParticipantsSearchList;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class AddPeoplePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "button.addpeople.create")
    private WebElement createButton;

    @iOSXCUITFindBy(accessibility = "button.addpeople.skip")
    private WebElement skipButton;

    @iOSXCUITFindBy(accessibility = "Back")
    private WebElement backButton;

    private static final Function<Integer, By> nameAddPeopleCount = count ->
            MobileBy.AccessibilityId(String.format("Add Participants (%s)", count));

    private final GroupParticipantsSearchList participantsSearchList;

    public AddPeoplePage(WebDriver driver) {
        super(driver);
        this.participantsSearchList = new GroupParticipantsSearchList(driver);
    }

    public void tapCreateButton(){
        createButton.click();
    }

    public void tapSkipButton(){
        skipButton.click();
    }

    public void tapBackButton(){
        backButton.click();
    }

    public boolean isParticipantsCountEqualTo(int expectedCount) {
        return isLocatorDisplayed(nameAddPeopleCount.apply(expectedCount));
    }

    public void typeSearchQuery(String query, boolean shouldClear) {
        participantsSearchList.typeSearchQuery(query, shouldClear);
    }

    public void selectItem(String name) {
        participantsSearchList.selectItem(name);
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
