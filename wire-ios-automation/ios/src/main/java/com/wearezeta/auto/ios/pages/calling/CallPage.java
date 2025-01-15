package com.wearezeta.auto.ios.pages.calling;

import com.wearezeta.auto.ios.pages.IOSPage;
import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

public class CallPage extends IOSPage {

    @iOSXCUITFindBy(iOSNsPredicate = "label == 'Constant Bit Rate'")
    private WebElement labelCBR;

    public CallPage(WebDriver driver) {
        super(driver);
    }

    public boolean isCBRLabelVisible() {
        return labelCBR.isDisplayed();
    }

    public boolean isCBRLabelInvisible() {
        return isElementInvisible(labelCBR);
    }
}
