/**
 * DETAILED VISIBILITY TEST - Shows what user actually sees
 */

const { test, expect } = require('@playwright/test');

test('detailed visibility analysis', async ({ page }) => {
    console.log('\n🔍 DETAILED VISIBILITY TEST\n');
    
    await page.goto('http://localhost:8000?t=' + Date.now());
    await page.waitForTimeout(6000);
    await page.click('[data-action="close-concierge"]');
    await page.waitForTimeout(1000);
    await page.click('#explore-btn');
    await page.waitForTimeout(1000);
    await page.click('text=The Experience');
    await page.waitForTimeout(1000);
    await page.click('[data-action="open-concierge"]');
    await page.waitForTimeout(3000);
    
    console.log('📸 Taking critical screenshot...\n');
    await page.screenshot({ path: 'visibility_test.png', fullPage: true });
    
    // Get what's ACTUALLY visible to the user
    const visibility = await page.evaluate(() => {
        const container = document.getElementById('concierge-messages');
        const messages = Array.from(container.querySelectorAll('.chat-msg'));
        const containerRect = container.getBoundingClientRect();
        
        // What can the user actually see?
        const visibleContent = [];
        
        messages.forEach((msg, idx) => {
            const rect = msg.getBoundingClientRect();
            
            // Calculate what portion is visible
            const visibleTop = Math.max(rect.top, containerRect.top);
            const visibleBottom = Math.min(rect.bottom, containerRect.bottom);
            const visibleHeight = Math.max(0, visibleBottom - visibleTop);
            const percentVisible = (visibleHeight / rect.height) * 100;
            
            if (percentVisible > 0) {
                visibleContent.push({
                    index: idx + 1,
                    text: msg.textContent.trim().substring(0, 100).replace(/\s+/g, ' '),
                    percentVisible: Math.round(percentVisible),
                    isOld: msg.textContent.includes("I'm your CoreSync concierge"),
                    isNew: msg.textContent.includes("explore CoreSync Private"),
                    isSeparator: msg.classList.contains('chat-msg--separator')
                });
            }
        });
        
        return {
            scrollTop: container.scrollTop,
            scrollHeight: container.scrollHeight,
            clientHeight: container.clientHeight,
            visibleContent,
            totalMessages: messages.length
        };
    });
    
    console.log('📊 CONTAINER STATE:');
    console.log(`   Total messages: ${visibility.totalMessages}`);
    console.log(`   scrollTop: ${visibility.scrollTop}px`);
    console.log(`   scrollHeight: ${visibility.scrollHeight}px`);
    console.log(`   clientHeight: ${visibility.clientHeight}px`);
    console.log(`   maxScroll: ${visibility.scrollHeight - visibility.clientHeight}px\n`);
    
    console.log('👁️  WHAT USER ACTUALLY SEES:\n');
    
    if (visibility.visibleContent.length === 0) {
        console.log('   ⚠️  NO MESSAGES VISIBLE (something is wrong!)\n');
    } else {
        visibility.visibleContent.forEach(msg => {
            const label = msg.isOld ? '🔵 OLD' : msg.isNew ? '🟢 NEW' : '⚪';
            const sepLabel = msg.isSeparator ? ' [SEPARATOR]' : '';
            console.log(`${label} Message ${msg.index}${sepLabel} - ${msg.percentVisible}% visible`);
            console.log(`   "${msg.text}..."`);
            console.log('');
        });
    }
    
    console.log('🎯 USER EXPERIENCE SUMMARY:\n');
    
    const oldVisible = visibility.visibleContent.find(m => m.isOld);
    const newVisible = visibility.visibleContent.find(m => m.isNew);
    
    if (oldVisible && newVisible) {
        console.log('   ❌ SHOWS HISTORY - Both old and new messages visible');
        console.log(`      Old message: ${oldVisible.percentVisible}% visible`);
        console.log(`      New message: ${newVisible.percentVisible}% visible`);
    } else if (newVisible && !oldVisible) {
        console.log('   ✅ LOOKS FRESH - Only new message visible');
        console.log(`      New message: ${newVisible.percentVisible}% visible`);
        console.log('      Old message is hidden (scrolled out of view)');
    } else if (oldVisible && !newVisible) {
        console.log('   ⚠️  Only old message visible (unexpected)');
    } else {
        console.log('   ❓ Unknown state');
    }
    
    console.log('\n✅ Test complete! Screenshot: visibility_test.png\n');
});
