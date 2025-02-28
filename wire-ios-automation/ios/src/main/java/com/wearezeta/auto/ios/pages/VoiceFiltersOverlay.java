package com.wearezeta.auto.ios.pages;

import io.appium.java_client.pagefactory.iOSXCUITFindBy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import java.util.Random;

public class VoiceFiltersOverlay extends IOSPage {

    @iOSXCUITFindBy(accessibility = "Start recording")
    private WebElement startRecordButton;

    @iOSXCUITFindBy(accessibility = "Stop recording")
    private WebElement stopRecordButton;

    @iOSXCUITFindBy(accessibility = "Send")
    private WebElement confirmRecordButton;

    @iOSXCUITFindBy(accessibility = "Helium")
    private WebElement effectHeliumButton;

    @iOSXCUITFindBy(accessibility = "Quick")
    private WebElement effectHareButton;

    @iOSXCUITFindBy(accessibility = "Deep voice")
    private WebElement effectJellyfishButton;

    @iOSXCUITFindBy(accessibility = "Hall effect")
    private WebElement effectCathedralButton;

    @iOSXCUITFindBy(accessibility = "Alien")
    private WebElement effectAlienButton;

    @iOSXCUITFindBy(accessibility = "Robotic")
    private WebElement effectVocoderMedButton;

    @iOSXCUITFindBy(accessibility = "High to deep")
    private WebElement effectRollerCoasterButton;

    private static final Random rand = new Random();

    public VoiceFiltersOverlay(WebDriver driver) {
        super(driver);
    }

    public void tapOnStartButton() {
        startRecordButton.click();
    }

    public void tapOnStopButton() {
        stopRecordButton.click();
    }

    public void tapOnConfirmButton() {
        confirmRecordButton.click();
    }

    public boolean isConfirmButtonVisible() {
        return confirmRecordButton.isDisplayed();
    }

    public boolean isConfirmButtonInVisible() {
        return isElementInvisible(confirmRecordButton);
    }

    public void tapRandomEffectButtons(int count) {
        final WebElement[] availableButtons = new WebElement[]{
                effectHeliumButton, effectJellyfishButton, effectHareButton, effectCathedralButton,
                effectAlienButton, effectVocoderMedButton, effectRollerCoasterButton
        };
        for (int i = 0; i < count; i++) {
            final WebElement locator = availableButtons[rand.nextInt(availableButtons.length)];
           locator.click();
        }
    }
}