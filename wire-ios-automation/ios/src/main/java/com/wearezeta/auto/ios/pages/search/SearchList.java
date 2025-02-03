package com.wearezeta.auto.ios.pages.search;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.Keys;

public class SearchList extends BaseSearchableItemsList {
    private static final String classChainStrViewRoot = "**/XCUIElementTypeCollectionView[`name == 'search.list'`]";

    public SearchList(WebDriver driver) {
        super(driver, classChainStrViewRoot);
    }

    public void tapInstantConnectButton(String name) {
        this.tapByPercentOfElementSize(getElement(classChainItemCellByName.apply(name)), 94, 50);
    }

    public int getOccurrencesCount(String name) {
        return selectVisibleElements(classChainItemNameByName.apply(name)).size();
    }

    public boolean isFederatedItemVisible(String name) {
        return super.isFederatedItemVisible(name);
    }

    public boolean isFederatedItemInvisible(String name) {
        return super.isFederatedItemInvisible(name);
    }

    @Override
    public boolean isUniqueUserNameLabelVisibleFor(String name) {
        return super.isUniqueUserNameLabelVisibleFor(name);
    }

    @Override
    public boolean isUniqueUserNameLabelInvisibleFor(String name) {
        return super.isUniqueUserNameLabelInvisibleFor(name);
    }

    @Override
    public void selectItem(String name) {
        super.selectItem(name);
    }

    @Override
    public boolean isItemVisible(String name) {
        return super.isItemVisible(name);
    }

    @Override
    public boolean isItemInvisible(String name) {
        return super.isItemInvisible(name);
    }

    @Override
    public boolean isGuestLabelVisibleFor(String name) {
        return super.isGuestLabelVisibleFor(name);
    }

    @Override
    public boolean isExternalLabelVisibleFor(String name) {
        return super.isExternalLabelVisibleFor(name);
    }

    @Override
    public boolean isExternalLabelInvisibleFor(String name) {
        return super.isExternalLabelInvisibleFor(name);
    }

    @Override
    public boolean isGuestLabelInvisibleFor(String name) {
        return super.isGuestLabelInvisibleFor(name);
    }

    @Override
    public void typeSearchQuery(String text) {
        super.typeSearchQuery(text);
    }

    @Override
    public void typeSearchQuery(String text, boolean shouldClearFieldBeforeInput) {
        super.typeSearchQuery(text, shouldClearFieldBeforeInput);
    }

    @Override
    public void sendKeysToSearchInput(Keys... keys) {
        super.sendKeysToSearchInput(keys);
    }

    @Override
    public String getCurrentSearchQuery() {
        return super.getCurrentSearchQuery();
    }
}