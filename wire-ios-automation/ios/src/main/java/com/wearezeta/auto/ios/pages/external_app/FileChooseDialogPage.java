package com.wearezeta.auto.ios.pages.external_app;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.MobileBy;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;

public class FileChooseDialogPage extends IOSPage {

    @iOSXCUITFindBy(accessibility = "DOC.itemCollectionMenuButton.Ellipsis")
    private WebElement ellipsisButton;

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeStaticText[`name == \"Recents\"`]")
    private WebElement header;

    @iOSXCUITFindBy(accessibility = "BackButton")
    private WebElement iPadBrowserButton;

    @iOSXCUITFindBy(accessibility = "DOC.sidebar.item.On My iPad")
    private WebElement onMyIPadSelection;

    @iOSXCUITFindBy(accessibility = "DOC.sortMenuButton.date")
    private WebElement sortByDateEntry;

    @iOSXCUITFindBy(accessibility = "DOC.sortMenuButton.date.descending")
    private WebElement sortByDateEntrySelected;

    @iOSXCUITFindBy(iOSNsPredicate = "name == 'Browse' AND type == 'XCUIElementTypeButton'")
    private WebElement browseFoldersButton;

    @iOSXCUITFindBy(accessibility = "On My iPhone")
    private WebElement onMyIPhoneSelection;

    private static String predicateStringFileByName = "type == 'XCUIElementTypeCell' AND label CONTAINS '%s'";

    public FileChooseDialogPage(WebDriver driver) {
        super(driver);
    }

    public void tapOnEllipsisButton() {
        ellipsisButton.click();
    }

    public void dismissEllipsisMenu() {
        //dismiss by tapping to the right of the menu
        Actions action = new Actions(getDriver());
        action.click(sortByDateEntrySelected).moveByOffset(150, 0).click().build().perform();
    }

    public void tapOnMyIPhone() {
        onMyIPhoneSelection.click();
    }

    public void tapOnMyIPad() {
        onMyIPadSelection.click();
    }

    public void tapFileContaining(String name) {
        waitUntilElementVisible(header);
        By locator = MobileBy.iOSNsPredicateString(String.format(predicateStringFileByName, name));
        isLocatorDisplayed(locator);
        getDriver().findElement(locator).click();
    }

    public void tapBrowseFoldersButton() {
        waitUntilElementVisible(browseFoldersButton);
        browseFoldersButton.click();
    }

    public void tapBrowserFolderButtonOnIPad(){
        waitUntilElementVisible(iPadBrowserButton);
        iPadBrowserButton.click();
    }

    public boolean isSortByDateNotSelected() {
        return isElementInvisible(sortByDateEntrySelected);
    }

    public void tapSortByDateEntry() {
        sortByDateEntry.click();
    }
}
