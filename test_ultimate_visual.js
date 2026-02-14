/**
 * ULTIMATE CRITICAL TEST - Complete Visual and Scroll Analysis
 * Tests initial view, scroll behavior, and ability to access old messages
 */

const { test, expect } = require('@playwright/test');

test('ultimate critical visual test with scroll analysis', async ({ page }) => {
    console.log('\n' + '='.repeat(80));
    console.log('🔬 ULTIMATE CRITICAL VISUAL TEST');
    console.log('='.repeat(80) + '\n');
    
    // Step 1
    console.log('STEP 1: Navigate to http://localhost:8000?t=fix2 (cache-busted)');
    await page.goto('http://localhost:8000?t=fix2');
    console.log('✓ Fresh page loaded\n');
    
    // Step 2
    console.log('STEP 2: Waiting 6 seconds for concierge to auto-open...');
    await page.waitForTimeout(6000);
    console.log('✓ 6 seconds elapsed\n');
    
    // Step 3
    console.log('STEP 3: Screenshot of initial state');
    await page.screenshot({ path: 'ultimate_01_initial.png', fullPage: true });
    const initialMsgs = await page.locator('.chat-msg').allTextContents();
    console.log(`📊 Initial: ${initialMsgs.length} message(s)`);
    console.log('✓ Screenshot: ultimate_01_initial.png\n');
    
    // Step 4
    console.log('STEP 4: Closing concierge (X button)');
    await page.click('[data-action="close-concierge"]');
    console.log('✓ Closed\n');
    
    // Step 5
    console.log('STEP 5: Wait 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Complete\n');
    
    // Step 6
    console.log('STEP 6: Click burger menu (#explore-btn)');
    await page.click('#explore-btn');
    console.log('✓ Explore opened\n');
    
    // Step 7
    console.log('STEP 7: Wait 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Complete\n');
    
    // Step 8
    console.log('STEP 8: Click "The Experience"');
    await page.click('text=The Experience');
    console.log('✓ Content loaded\n');
    
    // Step 9
    console.log('STEP 9: Wait 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Complete\n');
    
    // Step 10
    console.log('STEP 10: Click "Talk to the Concierge" button');
    await page.click('[data-action="open-concierge"]');
    console.log('✓ Clicked\n');
    
    // Step 11
    console.log('STEP 11: Wait 3 seconds for HTMX + scroll logic');
    await page.waitForTimeout(3000);
    console.log('✓ Complete\n');
    
    // Step 12 - CRITICAL ANALYSIS
    console.log('='.repeat(80));
    console.log('STEP 12: 🎯 CRITICAL SCREENSHOT & ANALYSIS');
    console.log('='.repeat(80) + '\n');
    
    await page.screenshot({ path: 'ultimate_02_critical.png', fullPage: true });
    console.log('✓ Critical screenshot: ultimate_02_critical.png\n');
    
    // Detailed analysis
    const criticalAnalysis = await page.locator('#concierge-messages').evaluate(container => {
        const messages = Array.from(container.querySelectorAll('.chat-msg'));
        const containerRect = container.getBoundingClientRect();
        
        const scrollInfo = {
            scrollTop: container.scrollTop,
            scrollHeight: container.scrollHeight,
            clientHeight: container.clientHeight,
            maxScroll: container.scrollHeight - container.clientHeight
        };
        
        const messageData = messages.map((msg, idx) => {
            const rect = msg.getBoundingClientRect();
            const topFromContainer = rect.top - containerRect.top;
            const bottomFromContainer = rect.bottom - containerRect.top;
            
            // Determine visibility
            const isAboveView = rect.bottom < containerRect.top;
            const isBelowView = rect.top > containerRect.bottom;
            const isInView = !isAboveView && !isBelowView;
            
            let visibleHeight = 0;
            if (isInView) {
                const visTop = Math.max(rect.top, containerRect.top);
                const visBottom = Math.min(rect.bottom, containerRect.bottom);
                visibleHeight = Math.max(0, visBottom - visTop);
            }
            const visPercent = rect.height > 0 ? (visibleHeight / rect.height * 100) : 0;
            
            return {
                index: idx + 1,
                fullText: msg.textContent.trim(),
                preview: msg.textContent.trim().substring(0, 80),
                isSeparator: msg.classList.contains('chat-msg--separator'),
                isUser: msg.classList.contains('chat-msg--user'),
                topPos: Math.round(topFromContainer * 10) / 10,
                bottomPos: Math.round(bottomFromContainer * 10) / 10,
                height: Math.round(rect.height * 10) / 10,
                isAboveView,
                isBelowView,
                isInView,
                visiblePercent: Math.round(visPercent)
            };
        });
        
        return { scrollInfo, messageData };
    });
    
    const { scrollInfo, messageData } = criticalAnalysis;
    
    console.log('📐 SCROLL CONTAINER STATE:');
    console.log(`   scrollTop: ${scrollInfo.scrollTop}px`);
    console.log(`   scrollHeight: ${scrollInfo.scrollHeight}px`);
    console.log(`   clientHeight: ${scrollInfo.clientHeight}px`);
    console.log(`   maxScroll: ${scrollInfo.maxScroll}px\n`);
    
    console.log('💬 MESSAGES IN DOM:\n');
    messageData.forEach(msg => {
        const type = msg.isSeparator ? '⭐ [SEPARATOR/NEW]' : msg.isUser ? '[USER]' : '[ASSISTANT/OLD]';
        let vis = '';
        if (msg.isAboveView) vis = '⬆️  ABOVE (hidden)';
        else if (msg.isBelowView) vis = '⬇️  BELOW (hidden)';
        else if (msg.visiblePercent === 100) vis = '👁️  FULLY VISIBLE';
        else if (msg.visiblePercent > 0) vis = `👀 ${msg.visiblePercent}% visible`;
        else vis = '❌ NOT VISIBLE';
        
        console.log(`Message ${msg.index} ${type} ${vis}`);
        console.log(`   Position: top=${msg.topPos}px, bottom=${msg.bottomPos}px (height: ${msg.height}px)`);
        console.log(`   Text: "${msg.preview}..."`);
        console.log('');
    });
    
    // Find specific messages
    const oldWelcome = messageData.find(m => m.fullText.includes("I'm your CoreSync concierge"));
    const newWelcome = messageData.find(m => m.isSeparator);
    const firstVisible = messageData.find(m => m.isInView);
    
    console.log('='.repeat(80));
    console.log('🎯 CRITICAL QUESTIONS - PRECISE ANSWERS:');
    console.log('='.repeat(80) + '\n');
    
    console.log('1️⃣  What is the FIRST visible message you see in the chat?');
    if (firstVisible) {
        const firstLine = firstVisible.fullText.split('\n')[0].trim();
        console.log(`   ✅ Message ${firstVisible.index}`);
        console.log(`   📝 EXACT TEXT (first line):`);
        console.log(`   "${firstLine}"`);
        console.log(`   Full preview: "${firstVisible.preview}..."`);
    } else {
        console.log('   ❌ No visible messages!');
    }
    console.log('');
    
    console.log('2️⃣  Is the OLD message "Welcome. I\'m your CoreSync concierge." visible or HIDDEN?');
    if (oldWelcome) {
        if (oldWelcome.isAboveView) {
            console.log('   ✅ HIDDEN - Scrolled ABOVE viewport (out of view)');
            console.log(`   The old message is at position ${oldWelcome.topPos}px (above visible area)`);
        } else if (oldWelcome.isBelowView) {
            console.log('   ⚠️  BELOW viewport (unusual)');
        } else {
            console.log('   ❌ VISIBLE - The old message IS visible in the viewport');
            console.log(`   Visibility: ${oldWelcome.visiblePercent}%`);
            console.log(`   Position: ${oldWelcome.topPos}px from container top`);
        }
    } else {
        console.log('   ℹ️  Old message not found in DOM');
    }
    console.log('');
    
    console.log('3️⃣  Does it look like a FRESH new chat?');
    const visibleMessages = messageData.filter(m => m.isInView && m.visiblePercent > 50);
    if (visibleMessages.length === 1 && visibleMessages[0].isSeparator) {
        console.log('   ✅ YES - Only the NEW contextual message is visible');
        console.log('   The chat appears fresh and contextual');
    } else if (visibleMessages.length === 1) {
        console.log('   ⚠️  Only 1 message visible, but it\'s the old one');
    } else {
        console.log('   ❌ NO - Multiple messages visible (shows history)');
        console.log(`   ${visibleMessages.length} messages are visible:`);
        visibleMessages.forEach(m => {
            const label = m.isSeparator ? '[NEW]' : '[OLD]';
            console.log(`      ${label} "${m.preview.substring(0, 50)}..."`);
        });
    }
    console.log('');
    
    console.log('4️⃣  What does the chat area look like overall?');
    if (scrollInfo.scrollTop === 0) {
        console.log('   📍 Scrolled to TOP (showing oldest content first)');
    } else if (scrollInfo.scrollTop >= scrollInfo.maxScroll - 1) {
        console.log('   📍 Scrolled to BOTTOM (showing newest content)');
    } else {
        const pct = (scrollInfo.scrollTop / scrollInfo.maxScroll * 100).toFixed(1);
        console.log(`   📍 Scrolled ${pct}% down from top`);
    }
    
    if (scrollInfo.maxScroll === 0) {
        console.log('   📏 All content fits (no scrolling needed)');
    } else {
        console.log(`   📏 Content is scrollable (${scrollInfo.maxScroll}px of scroll available)`);
    }
    
    console.log(`   💬 ${messageData.length} total messages in chat`);
    console.log(`   👁️  ${visibleMessages.length} visible to user`);
    console.log('');
    
    // Step 13 - Scroll UP test
    console.log('='.repeat(80));
    console.log('STEP 13: 📜 SCROLL UP TEST');
    console.log('='.repeat(80) + '\n');
    
    const canScroll = scrollInfo.maxScroll > 0;
    
    if (canScroll) {
        console.log('Attempting to scroll UP in the chat area...');
        
        // Scroll up by wheel event
        await page.locator('#concierge-messages').evaluate(el => {
            el.scrollTop = Math.max(0, el.scrollTop - 200);
        });
        
        await page.waitForTimeout(500);
        console.log('✓ Scrolled up\n');
    } else {
        console.log('⚠️  Cannot scroll - all content already fits in viewport');
        console.log('   Attempting to scroll anyway to verify...\n');
        
        await page.locator('#concierge-messages').evaluate(el => {
            el.scrollTop = 0; // Try to force to top
        });
        
        await page.waitForTimeout(500);
    }
    
    // Step 14 - Screenshot after scroll
    console.log('STEP 14: Screenshot after scroll attempt');
    await page.screenshot({ path: 'ultimate_03_after_scroll.png', fullPage: true });
    console.log('✓ Screenshot: ultimate_03_after_scroll.png\n');
    
    // Step 15 - Check what's visible now
    console.log('STEP 15: 🔍 What\'s visible after scrolling up?\n');
    
    const afterScrollAnalysis = await page.locator('#concierge-messages').evaluate(container => {
        const messages = Array.from(container.querySelectorAll('.chat-msg'));
        const containerRect = container.getBoundingClientRect();
        
        return {
            scrollTop: container.scrollTop,
            messages: messages.map((msg, idx) => {
                const rect = msg.getBoundingClientRect();
                const isInView = rect.bottom > containerRect.top && rect.top < containerRect.bottom;
                return {
                    index: idx + 1,
                    text: msg.textContent.trim().substring(0, 60),
                    isOldWelcome: msg.textContent.includes("I'm your CoreSync concierge"),
                    isSeparator: msg.classList.contains('chat-msg--separator'),
                    isInView
                };
            })
        };
    });
    
    console.log(`📍 Scroll position after scroll up: ${afterScrollAnalysis.scrollTop}px\n`);
    
    const oldNowVisible = afterScrollAnalysis.messages.find(m => m.isOldWelcome && m.isInView);
    
    console.log('❓ Can you now see the old message after scrolling?');
    if (oldNowVisible) {
        console.log('   ✅ YES - The old "Welcome. I\'m your CoreSync concierge." message is NOW VISIBLE');
        console.log('   (It was scrolled into view)');
    } else {
        const oldExists = afterScrollAnalysis.messages.find(m => m.isOldWelcome);
        if (oldExists) {
            if (oldExists.isInView) {
                console.log('   ✅ YES - The old message is visible');
            } else {
                console.log('   ❌ NO - The old message still hidden (scroll didn\'t reveal it)');
            }
        } else {
            console.log('   ℹ️  Old message not in DOM');
        }
    }
    console.log('');
    
    const visibleNow = afterScrollAnalysis.messages.filter(m => m.isInView);
    console.log(`Messages visible after scroll: ${visibleNow.length}`);
    visibleNow.forEach(m => {
        const label = m.isSeparator ? '[NEW]' : m.isOldWelcome ? '[OLD]' : '[MSG]';
        console.log(`   ${label} "${m.text}..."`);
    });
    
    console.log('\n' + '='.repeat(80));
    console.log('✅ ULTIMATE TEST COMPLETE');
    console.log('='.repeat(80));
    console.log('Screenshots:');
    console.log('  1. ultimate_01_initial.png - Initial auto-open');
    console.log('  2. ultimate_02_critical.png - After reopening with context');
    console.log('  3. ultimate_03_after_scroll.png - After scrolling up');
    console.log('='.repeat(80) + '\n');
});
