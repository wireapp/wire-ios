package com.wearezeta.auto.ios.pages.details_overlay.group;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

import java.util.function.Function;

public class GroupPeoplePage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "GROUP MEMBERS")
    private WebElement membersSection;

    @iOSXCUITFindBy(accessibility = "GROUP ADMINS")
    private WebElement adminsSection;

    private static final Function<String, By> classChainExternalIconForUser = name ->
            MobileBy.iOSClassChain(String.format("**/XCUIElementTypeCollectionView[`name == 'group_details.full_list'`]/XCUIElementTypeCell[`name ENDSWITH 'participants.section.participants.cell'`][$name == 'user_cell.name' AND value == '%s' OR name == 'user_cell.name' AND value == '%s (You)'$]/**/XCUIElementTypeImage[`name == 'img.external'`]", name, name
            ));

    private static final Function<String, By> classChainUserInAdminSection = userName ->
            MobileBy.iOSClassChain(String.format("**/XCUIElementTypeCollectionView[`name == " +
                    "'group_details.full_list'`]/*[`name == 'Admins - participants.section.participants.cell'`]/**/XCUIElementTypeStaticText[`value == '%s' OR value == '%s (You)'`]", userName, userName));

    private static final Function<String, By> classChainUser = userName ->
            MobileBy.iOSClassChain(String.format("**/XCUIElementTypeCollectionView[`name == " +
                    "'group_details.full_list'`]/*[`name ENDSWITH 'participants.section.participants.cell'`]/**/XCUIElementTypeStaticText[`value == '%s' OR value == '%s (You)'`]", userName, userName));

    public GroupPeoplePage(WebDriver driver) {
        super(driver);
    }

    public boolean isExternalIndicatorVisibleFor(String name) {
        return isLocatorDisplayed(classChainExternalIconForUser.apply(name));
    }

    public boolean isMembersSectionVisible() {
        return membersSection.isDisplayed();
    }

    public boolean isMembersSectionInvisible() {
        return isElementInvisible(membersSection);
    }

    public boolean isAdminsSectionVisible() {
        return adminsSection.isDisplayed();
    }

    public boolean isAdminsSectionInvisible() {
        return isElementInvisible(adminsSection);
    }

    public boolean isUserInAdminsSection(String userName) {
        return isLocatorDisplayed(classChainUserInAdminSection.apply(userName));
    }

    public boolean isUserNotInAdminsSection(String userName) {
        return isLocatorInvisible(classChainUserInAdminSection.apply(userName));
    }

    public void selectParticipantPeoplePage(String name) {
        getElement(classChainUser.apply(name)).click();
    }
}
