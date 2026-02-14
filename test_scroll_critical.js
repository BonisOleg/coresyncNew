/**
 * MOST CRITICAL TEST - Scroll Behavior and Visible Content Analysis
 * This test checks EXACTLY what the user sees after reopening concierge
 */

const { test, expect } = require('@playwright/test');

test('critical scroll behavior test', async ({ page }) => {
    console.log('\n' + '='.repeat(80));
    console.log('🔬 CRITICAL VISUAL TEST - SCROLL BEHAVIOR ANALYSIS');
    console.log('='.repeat(80) + '\n');
    
    // Step 1 - Fresh page load
    console.log('STEP 1: Navigate to http://localhost:8000 (fresh, with cache-busting)');
    await page.goto('http://localhost:8000?t=' + Date.now());
    console.log('✓ Page loaded\n');
    
    // Step 2 - Wait for auto-open
    console.log('STEP 2: Waiting 6 seconds for concierge to auto-open...');
    await page.waitForTimeout(6000);
    console.log('✓ 6 seconds elapsed\n');
    
    // Step 3 - First screenshot
    console.log('STEP 3: Taking screenshot of initial auto-opened state');
    await page.screenshot({ path: 'scroll_test_01_initial.png', fullPage: true });
    
    const initialMsgs = await page.locator('.chat-msg').allTextContents();
    console.log(`📊 Initial state: ${initialMsgs.length} message(s) visible`);
    initialMsgs.forEach((msg, i) => {
        console.log(`   ${i + 1}. "${msg.trim().substring(0, 60)}..."`);
    });
    console.log('✓ Screenshot saved: scroll_test_01_initial.png\n');
    
    // Step 4 - Close concierge
    console.log('STEP 4: Clicking X button to close concierge');
    await page.click('[data-action="close-concierge"]');
    console.log('✓ Concierge closed\n');
    
    // Step 5 - Wait
    console.log('STEP 5: Waiting 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Wait complete\n');
    
    // Step 6 - Open explore menu
    console.log('STEP 6: Clicking burger menu button (#explore-btn)');
    await page.click('#explore-btn');
    console.log('✓ Explore menu opened\n');
    
    // Step 7 - Wait
    console.log('STEP 7: Waiting 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Wait complete\n');
    
    // Step 8 - Click "The Experience"
    console.log('STEP 8: Clicking "The Experience" link');
    await page.click('text=The Experience');
    console.log('✓ Experience content loaded\n');
    
    // Step 9 - Wait
    console.log('STEP 9: Waiting 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Wait complete\n');
    
    // Step 10 - Reopen concierge with context
    console.log('STEP 10: Clicking "Talk to the Concierge" button');
    await page.click('[data-action="open-concierge"]');
    console.log('✓ Button clicked\n');
    
    // Step 11 - Wait for HTMX and scroll logic
    console.log('STEP 11: Waiting 3 seconds for HTMX load and scroll logic...');
    await page.waitForTimeout(3000);
    console.log('✓ 3 seconds elapsed\n');
    
    // Step 12 - CRITICAL ANALYSIS
    console.log('='.repeat(80));
    console.log('STEP 12: 🎯 CRITICAL SCREENSHOT & DETAILED ANALYSIS');
    console.log('='.repeat(80) + '\n');
    
    await page.screenshot({ path: 'scroll_test_02_critical.png', fullPage: true });
    console.log('✓ Critical screenshot saved: scroll_test_02_critical.png\n');
    
    // Get scroll container details
    const scrollData = await page.locator('#concierge-messages').evaluate(el => {
        const rect = el.getBoundingClientRect();
        return {
            scrollTop: el.scrollTop,
            scrollHeight: el.scrollHeight,
            clientHeight: el.clientHeight,
            maxScroll: el.scrollHeight - el.clientHeight,
            containerTop: rect.top,
            containerBottom: rect.bottom,
            containerHeight: rect.height
        };
    });
    
    console.log('📐 MESSAGES CONTAINER MEASUREMENTS:');
    console.log(`   scrollTop: ${scrollData.scrollTop}px`);
    console.log(`   scrollHeight: ${scrollData.scrollHeight}px (total content height)`);
    console.log(`   clientHeight: ${scrollData.clientHeight}px (visible viewport height)`);
    console.log(`   maxScroll: ${scrollData.maxScroll}px (maximum scrollable distance)`);
    console.log(`   containerTop: ${scrollData.containerTop}px (from page top)`);
    console.log(`   containerBottom: ${scrollData.containerBottom}px\n`);
    
    if (scrollData.maxScroll > 0) {
        const scrollPercent = (scrollData.scrollTop / scrollData.maxScroll * 100).toFixed(1);
        console.log(`📍 SCROLL POSITION: ${scrollPercent}% (0% = top, 100% = bottom)\n`);
    } else {
        console.log(`📍 SCROLL POSITION: No scrolling possible (all content fits)\n`);
    }
    
    // Get ALL message details with visibility info
    const messageAnalysis = await page.locator('.chat-msg').evaluateAll((messages, scrollData) => {
        const container = document.getElementById('concierge-messages');
        const containerRect = container.getBoundingClientRect();
        
        return messages.map((msg, index) => {
            const rect = msg.getBoundingClientRect();
            const topRelative = rect.top - containerRect.top;
            const bottomRelative = rect.bottom - containerRect.top;
            
            // Check if message is visible in viewport
            const isTopVisible = rect.top >= containerRect.top && rect.top < containerRect.bottom;
            const isBottomVisible = rect.bottom > containerRect.top && rect.bottom <= containerRect.bottom;
            const isFullyVisible = isTopVisible && isBottomVisible;
            const isPartiallyVisible = (isTopVisible || isBottomVisible) || 
                                      (rect.top < containerRect.top && rect.bottom > containerRect.bottom);
            
            return {
                index: index + 1,
                text: msg.textContent.trim(),
                textPreview: msg.textContent.trim().substring(0, 70),
                isSeparator: msg.classList.contains('chat-msg--separator'),
                isUser: msg.classList.contains('chat-msg--user'),
                isAssistant: msg.classList.contains('chat-msg--assistant'),
                topRelative: Math.round(topRelative * 100) / 100,
                bottomRelative: Math.round(bottomRelative * 100) / 100,
                height: Math.round(rect.height * 100) / 100,
                isFullyVisible,
                isPartiallyVisible,
                isAboveViewport: rect.bottom <= containerRect.top,
                isBelowViewport: rect.top >= containerRect.bottom,
                visibilityPercent: (() => {
                    if (rect.bottom <= containerRect.top || rect.top >= containerRect.bottom) return 0;
                    const visibleTop = Math.max(rect.top, containerRect.top);
                    const visibleBottom = Math.min(rect.bottom, containerRect.bottom);
                    const visibleHeight = visibleBottom - visibleTop;
                    return Math.round((visibleHeight / rect.height) * 100);
                })()
            };
        });
    }, scrollData);
    
    console.log('💬 ALL MESSAGES IN DOM (top to bottom order):\n');
    
    messageAnalysis.forEach(msg => {
        const typeLabel = msg.isSeparator ? '⭐ [SEPARATOR]' : msg.isUser ? '[USER]' : '[ASSISTANT]';
        
        let visLabel;
        if (msg.isAboveViewport) {
            visLabel = '⬆️  ABOVE VIEWPORT (scrolled out of view)';
        } else if (msg.isBelowViewport) {
            visLabel = '⬇️  BELOW VIEWPORT (scrolled out of view)';
        } else if (msg.isFullyVisible) {
            visLabel = '👁️  FULLY VISIBLE';
        } else if (msg.isPartiallyVisible) {
            visLabel = `👀 PARTIALLY VISIBLE (${msg.visibilityPercent}%)`;
        } else {
            visLabel = '❌ NOT VISIBLE';
        }
        
        console.log(`Message ${msg.index} ${typeLabel} ${visLabel}`);
        console.log(`   Top: ${msg.topRelative >= 0 ? '+' : ''}${msg.topRelative}px from container top`);
        console.log(`   Bottom: ${msg.bottomRelative >= 0 ? '+' : ''}${msg.bottomRelative}px from container top`);
        console.log(`   Height: ${msg.height}px`);
        console.log(`   Text: "${msg.textPreview}..."`);
        console.log('');
    });
    
    // Find what's visible in viewport
    const visibleMessages = messageAnalysis.filter(m => m.isFullyVisible || m.isPartiallyVisible);
    const fullyVisibleMessages = messageAnalysis.filter(m => m.isFullyVisible);
    const firstVisibleMessage = messageAnalysis.find(m => m.isFullyVisible || m.isPartiallyVisible);
    const oldWelcomeMessage = messageAnalysis.find(m => 
        m.text.includes("I'm your CoreSync concierge")
    );
    
    console.log('='.repeat(80));
    console.log('🎯 CRITICAL QUESTIONS ANSWERED:');
    console.log('='.repeat(80) + '\n');
    
    console.log('❓ What is the FIRST visible message in the chat area?');
    if (firstVisibleMessage) {
        console.log(`   ✅ Message ${firstVisibleMessage.index}`);
        console.log(`   📝 EXACT TEXT:`);
        console.log(`   "${firstVisibleMessage.text.substring(0, 120)}..."`);
        console.log('');
    } else {
        console.log('   ❌ No visible messages found!\n');
    }
    
    console.log('❓ Is the OLD "Welcome. I\'m your CoreSync concierge." message visible or hidden?');
    if (oldWelcomeMessage) {
        if (oldWelcomeMessage.isAboveViewport) {
            console.log('   ✅ HIDDEN - Scrolled above the viewport (out of view)');
        } else if (oldWelcomeMessage.isFullyVisible) {
            console.log('   ❌ FULLY VISIBLE - The old message is completely visible');
        } else if (oldWelcomeMessage.isPartiallyVisible) {
            console.log(`   ⚠️  PARTIALLY VISIBLE - ${oldWelcomeMessage.visibilityPercent}% visible`);
        } else if (oldWelcomeMessage.isBelowViewport) {
            console.log('   ❓ BELOW VIEWPORT - Scrolled below (unusual)');
        }
        console.log(`   Position: ${oldWelcomeMessage.topRelative >= 0 ? '+' : ''}${oldWelcomeMessage.topRelative}px from container top`);
    } else {
        console.log('   ℹ️  Old message not found in DOM');
    }
    console.log('');
    
    console.log('❓ Does the chat look like a FRESH new chat with only the newest message visible?');
    if (fullyVisibleMessages.length === 1 && fullyVisibleMessages[0].isSeparator) {
        console.log('   ✅ YES - Only the new contextual message is fully visible');
        console.log('   (This would appear as a fresh chat to the user)');
    } else if (fullyVisibleMessages.length === 1) {
        console.log('   ⚠️  Only 1 message visible, but it\'s not the separator/new message');
    } else {
        console.log(`   ❌ NO - ${fullyVisibleMessages.length} messages are fully visible`);
        console.log('   (User can see chat history)');
        fullyVisibleMessages.forEach(m => {
            const label = m.isSeparator ? '[NEW]' : '[OLD]';
            console.log(`      ${label} Message ${m.index}: "${m.textPreview}..."`);
        });
    }
    console.log('');
    
    console.log('❓ What is the scroll position of the messages container?');
    console.log(`   scrollTop = ${scrollData.scrollTop}px`);
    if (scrollData.scrollTop === 0) {
        console.log('   ➡️  Container is scrolled to the VERY TOP');
        console.log('   (Shows the first/oldest content)');
    } else if (scrollData.scrollTop >= scrollData.maxScroll - 1) {
        console.log('   ➡️  Container is scrolled to the VERY BOTTOM');
        console.log('   (Shows the last/newest content)');
    } else if (scrollData.maxScroll === 0) {
        console.log('   ➡️  No scrolling (all content fits in viewport)');
    } else {
        const percent = (scrollData.scrollTop / scrollData.maxScroll * 100).toFixed(1);
        console.log(`   ➡️  Scrolled ${percent}% down from top`);
    }
    console.log('');
    
    console.log('='.repeat(80));
    console.log('📊 SUMMARY:');
    console.log('='.repeat(80));
    console.log(`   Total messages in DOM: ${messageAnalysis.length}`);
    console.log(`   Fully visible: ${fullyVisibleMessages.length}`);
    console.log(`   Partially visible: ${visibleMessages.length - fullyVisibleMessages.length}`);
    console.log(`   Hidden above viewport: ${messageAnalysis.filter(m => m.isAboveViewport).length}`);
    console.log(`   Hidden below viewport: ${messageAnalysis.filter(m => m.isBelowViewport).length}`);
    console.log('');
    console.log('✅ Critical test complete!');
    console.log('   Screenshots: scroll_test_01_initial.png, scroll_test_02_critical.png');
    console.log('='.repeat(80) + '\n');
});
