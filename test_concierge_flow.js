/**
 * Test script for CoreSync concierge flow
 * Run with: npx playwright test test_concierge_flow.js --headed
 */

const { test, expect } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

// Create screenshots directory if it doesn't exist
const screenshotsDir = path.join(__dirname, 'test_screenshots');
if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir);
}

test('concierge flow test', async ({ page }) => {
    console.log('\n=== STEP 1: Navigate to http://localhost:8000 ===');
    await page.goto('http://localhost:8000');
    await page.screenshot({ path: path.join(screenshotsDir, '01_initial_load.png'), fullPage: true });
    console.log('✓ Screenshot saved: 01_initial_load.png');

    console.log('\n=== STEP 2: Wait 5 seconds for concierge to auto-open ===');
    await page.waitForTimeout(5000);
    await page.screenshot({ path: path.join(screenshotsDir, '02_concierge_auto_opened.png'), fullPage: true });
    console.log('✓ Screenshot saved: 02_concierge_auto_opened.png');

    // Check if concierge panel is open
    const conciergePanelOpen = await page.locator('#concierge-panel.is-open').count();
    console.log(`Concierge panel open: ${conciergePanelOpen > 0 ? 'YES' : 'NO'}`);

    // Check for welcome message and buttons
    const messages = await page.locator('.chat-msg').count();
    const buttons = await page.locator('.chat-btn').count();
    console.log(`Messages visible: ${messages}`);
    console.log(`Buttons visible: ${buttons}`);

    console.log('\n=== STEP 3: Close concierge by clicking X button ===');
    await page.click('[data-action="close-concierge"]');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(screenshotsDir, '03_concierge_closed.png'), fullPage: true });
    console.log('✓ Screenshot saved: 03_concierge_closed.png');

    console.log('\n=== STEP 4: Check if burger menu button appeared ===');
    const burgerMenuVisible = await page.locator('#explore-btn').isVisible();
    console.log(`Burger menu (#explore-btn) visible: ${burgerMenuVisible ? 'YES ✓' : 'NO ✗'}`);
    
    if (!burgerMenuVisible) {
        console.log('ERROR: Burger menu did not appear after closing concierge!');
        const hasHiddenClass = await page.locator('#explore-btn.is-hidden').count() > 0;
        console.log(`Has is-hidden class: ${hasHiddenClass}`);
    }

    console.log('\n=== STEP 5: Click burger menu to open explore panel ===');
    await page.click('#explore-btn');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(screenshotsDir, '04_explore_panel_opened.png'), fullPage: true });
    console.log('✓ Screenshot saved: 04_explore_panel_opened.png');

    // Check if explore panel is open
    const explorePanelOpen = await page.locator('#explore-panel.is-open').count();
    console.log(`Explore panel open: ${explorePanelOpen > 0 ? 'YES' : 'NO'}`);

    console.log('\n=== STEP 6: Click "The Experience" link ===');
    await page.click('text=The Experience');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(screenshotsDir, '05_experience_content.png'), fullPage: true });
    console.log('✓ Screenshot saved: 05_experience_content.png');

    console.log('\n=== STEP 7: Click "Talk to the Concierge" button ===');
    // Get chat message count BEFORE opening
    const messagesBefore = await page.locator('.chat-msg').count();
    console.log(`Messages BEFORE reopening: ${messagesBefore}`);

    await page.click('[data-action="open-concierge"]');
    console.log('Clicked Talk to the Concierge button');

    console.log('\n=== STEP 8: Wait 2 seconds for HTMX to load ===');
    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(screenshotsDir, '06_concierge_reopened.png'), fullPage: true });
    console.log('✓ Screenshot saved: 06_concierge_reopened.png');

    // Get chat message count AFTER opening
    const messagesAfter = await page.locator('.chat-msg').count();
    console.log(`Messages AFTER reopening: ${messagesAfter}`);

    // Check scroll position
    const scrollContainer = page.locator('#concierge-messages');
    const scrollTop = await scrollContainer.evaluate(el => el.scrollTop);
    const scrollHeight = await scrollContainer.evaluate(el => el.scrollHeight);
    const clientHeight = await scrollContainer.evaluate(el => el.clientHeight);
    const maxScroll = scrollHeight - clientHeight;

    console.log(`\nScroll Analysis:`);
    console.log(`  scrollTop: ${scrollTop}px`);
    console.log(`  scrollHeight: ${scrollHeight}px`);
    console.log(`  clientHeight: ${clientHeight}px`);
    console.log(`  maxScroll: ${maxScroll}px`);
    console.log(`  Scrolled to: ${(scrollTop / maxScroll * 100).toFixed(1)}%`);

    // Check for separator
    const separator = await page.locator('.chat-msg--separator').count();
    console.log(`\nSeparator messages found: ${separator}`);
    
    if (separator > 0) {
        const separatorText = await page.locator('.chat-msg--separator').first().textContent();
        console.log(`Separator text: "${separatorText.trim().substring(0, 50)}..."`);
    }

    // Check for duplicate messages
    const allMessages = await page.locator('.chat-msg').allTextContents();
    console.log(`\nAll messages in chat (${allMessages.length} total):`);
    allMessages.forEach((msg, idx) => {
        const preview = msg.trim().replace(/\n/g, ' ').substring(0, 60);
        console.log(`  ${idx + 1}. ${preview}...`);
    });

    // Check for duplicates
    const messageCounts = {};
    allMessages.forEach(msg => {
        const key = msg.trim();
        messageCounts[key] = (messageCounts[key] || 0) + 1;
    });
    
    const duplicates = Object.entries(messageCounts).filter(([_, count]) => count > 1);
    if (duplicates.length > 0) {
        console.log(`\n⚠ DUPLICATE MESSAGES FOUND:`);
        duplicates.forEach(([msg, count]) => {
            console.log(`  - "${msg.substring(0, 40)}..." appears ${count} times`);
        });
    } else {
        console.log(`\n✓ No duplicate messages found`);
    }

    console.log('\n=== TEST COMPLETE ===');
    console.log(`\nScreenshots saved in: ${screenshotsDir}`);
});
