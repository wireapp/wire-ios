package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;


public class ServiceDetailPage extends IOSPage{
    @iOSXCUITFindBy(accessibility = "Add Service")
    private WebElement nameAddServiceButton;

    public ServiceDetailPage(WebDriver driver) {
        super(driver);
    }

    public void addService(){
        nameAddServiceButton.click();
    }
}
