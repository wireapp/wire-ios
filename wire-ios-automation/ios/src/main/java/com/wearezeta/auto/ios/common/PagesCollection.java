package com.wearezeta.auto.ios.common;

import com.wearezeta.auto.common.log.ZetaLogger;
import io.appium.java_client.pagefactory.AppiumFieldDecorator;
import java.util.logging.Logger;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.PageFactory;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

public class PagesCollection {
	private final Logger log = ZetaLogger.getLog(this.getClass().getSimpleName());

	private final WebDriver driver;

	public PagesCollection(WebDriver driver) {
		this.driver = driver;
	}

	public <T> T getPage(Class<T> pageClass) {
		log.info("Page: " + pageClass.getSimpleName());
		try {
			final Constructor<?> constructor = pageClass.getConstructor(WebDriver.class);
			T instance = pageClass.cast(constructor.newInstance(this.driver));
			PageFactory.initElements(new AppiumFieldDecorator(this.driver), instance);
			return instance;
		} catch (NoSuchMethodException | InstantiationException | IllegalAccessException | InvocationTargetException e) {
			throw new RuntimeException("Could not instantiate page " + pageClass, e);
		}
	}
}
