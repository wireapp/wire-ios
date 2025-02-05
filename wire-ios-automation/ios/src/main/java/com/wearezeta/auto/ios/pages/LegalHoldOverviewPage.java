package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import io.appium.java_client.MobileBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import java.util.function.Function;

public class LegalHoldOverviewPage extends IOSPage {

    @iOSXCUITFindBy(iOSClassChain = "**/XCUIElementTypeCollectionView[`name == 'list.legalhold'`]")
    private WebElement legalHoldPage;

    private static final String classChainLegalHoldTitle = "**/XCUIElementTypeNavigationBar[`name == 'LEGAL HOLD'`]";

    private static final String strItemName = "user_cell.name";

    private static final String classChainstrViewRoot = "**/XCUIElementTypeCell[`name == 'participants.section.participants.cell'`]";

    private final By classChainCloseButton = MobileBy.iOSClassChain(String.format("%s/XCUIElementTypeButton[$name == '%s'$]",
            classChainLegalHoldTitle, "close"));

    private final Function<String, String> classChainStrItemCellByName = name ->
            String.format("%s/**/XCUIElementTypeStaticText[$name == '%s' AND value CONTAINS '%s'$]",
                    classChainstrViewRoot, strItemName, name);

    private final Function<String, By> classChainItemCellByName = name -> MobileBy.iOSClassChain(
            classChainStrItemCellByName.apply(name));

    public LegalHoldOverviewPage(WebDriver driver) {
        super(driver);
    }

    public boolean isVisible() {
        return legalHoldPage.isDisplayed();
    }

    public boolean isInvisible() {
        return isElementInvisible(legalHoldPage);
    }

    public boolean isMyselfVisible(String name) {
        return isSubjectDisplayNameVisible(name+" (You)");
    }

    public boolean isSubjectDisplayNameVisible(String name) {
        return isLocatorDisplayed(classChainItemCellByName.apply(name));
    }

    public boolean isSubjectDisplayNameInvisible(String name) {
        return isLocatorInvisible(classChainItemCellByName.apply(name));
    }

    public void tapOnSubject(String name) {
        getElement(classChainItemCellByName.apply(name)).click();
    }

    public void tapCloseButton() {
        this.tapAtTheCenterOfElement(getElement(classChainCloseButton));
    }
}
