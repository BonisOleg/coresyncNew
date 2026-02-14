/**
 * ULTIMATE SCROLL TEST - With manual scroll verification
 * Tests visibility AND scrollability of messages
 */

const { test, expect } = require('@playwright/test');

test('ultimate scroll test with scroll verification', async ({ page }) => {
    console.log('\n' + '='.repeat(80));
    console.log('🔬 ULTIMATE SCROLL TEST - WITH MANUAL SCROLL VERIFICATION');
    console.log('='.repeat(80) + '\n');
    
    // Step 1
    console.log('STEP 1: Navigate to http://localhost:8000?nocache=1');
    await page.goto('http://localhost:8000?nocache=1');
    console.log('✓ Fresh page loaded\n');
    
    // Step 2
    console.log('STEP 2: Waiting 6 seconds for concierge to auto-open...');
    await page.waitForTimeout(6000);
    console.log('✓ Wait complete\n');
    
    // Step 3
    console.log('STEP 3: Taking screenshot of initial state');
    await page.screenshot({ path: 'ultimate_01_initial.png', fullPage: true });
    console.log('✓ Screenshot saved\n');
    
    // Step 4
    console.log('STEP 4: Closing concierge (clicking X button)');
    await page.click('[data-action="close-concierge"]');
    console.log('✓ Closed\n');
    
    // Step 5
    console.log('STEP 5: Waiting 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Done\n');
    
    // Step 6
    console.log('STEP 6: Clicking burger menu (#explore-btn)');
    await page.click('#explore-btn');
    console.log('✓ Opened\n');
    
    // Step 7
    console.log('STEP 7: Waiting 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Done\n');
    
    // Step 8
    console.log('STEP 8: Clicking "The Experience" link');
    await page.click('text=The Experience');
    console.log('✓ Clicked\n');
    
    // Step 9
    console.log('STEP 9: Waiting 1 second');
    await page.waitForTimeout(1000);
    console.log('✓ Done\n');
    
    // Step 10
    console.log('STEP 10: Clicking "Talk to the Concierge" button');
    await page.click('[data-action="open-concierge"]');
    console.log('✓ Clicked\n');
    
    // Step 11
    console.log('STEP 11: Waiting 3 seconds for HTMX and scroll logic...');
    await page.waitForTimeout(3000);
    console.log('✓ Done\n');
    
    // Step 12 - CRITICAL ANALYSIS
    console.log('='.repeat(80));
    console.log('STEP 12: 🎯 CRITICAL SCREENSHOT & ANALYSIS');
    console.log('='.repeat(80) + '\n');
    
    await page.screenshot({ path: 'ultimate_02_critical.png', fullPage: true });
    console.log('✓ Critical screenshot saved: ultimate_02_critical.png\n');
    
    // Get detailed message analysis
    const analysis = await page.locator('#concierge-messages').evaluate(container => {
        const containerRect = container.getBoundingClientRect();
        const messages = Array.from(container.querySelectorAll('.chat-msg'));
        
        return {
            scroll: {
                scrollTop: container.scrollTop,
                scrollHeight: container.scrollHeight,
                clientHeight: container.clientHeight,
                maxScroll: container.scrollHeight - container.clientHeight
            },
            messages: messages.map((msg, idx) => {
                const rect = msg.getBoundingClientRect();
                const topRelative = rect.top - containerRect.top;
                const bottomRelative = rect.bottom - containerRect.top;
                
                return {
                    index: idx + 1,
                    text: msg.textContent.trim(),
                    preview: msg.textContent.trim().substring(0, 80).replace(/\s+/g, ' '),
                    isSeparator: msg.classList.contains('chat-msg--separator'),
                    isOldMessage: msg.textContent.includes("I'm your CoreSync concierge"),
                    isNewMessage: msg.textContent.includes("explore CoreSync Private"),
                    topRelative: Math.round(topRelative * 10) / 10,
                    bottomRelative: Math.round(bottomRelative * 10) / 10,
                    height: Math.round(rect.height * 10) / 10,
                    isInViewport: topRelative < container.clientHeight && bottomRelative > 0,
                    isFullyVisible: topRelative >= 0 && bottomRelative <= container.clientHeight,
                    isAboveViewport: bottomRelative <= 0,
                    isBelowViewport: topRelative >= container.clientHeight
                };
            })
        };
    });
    
    console.log('📐 SCROLL MEASUREMENTS:');
    console.log(`   scrollTop: ${analysis.scroll.scrollTop}px`);
    console.log(`   scrollHeight: ${analysis.scroll.scrollHeight}px`);
    console.log(`   clientHeight: ${analysis.scroll.clientHeight}px`);
    console.log(`   maxScroll: ${analysis.scroll.maxScroll}px\n`);
    
    console.log('💬 MESSAGES ANALYSIS:\n');
    analysis.messages.forEach(msg => {
        const label = msg.isOldMessage ? '🔵 OLD' : msg.isNewMessage ? '🟢 NEW' : '⚪';
        const sepLabel = msg.isSeparator ? ' [SEPARATOR]' : '';
        const visLabel = msg.isAboveViewport ? '⬆️ ABOVE' : 
                        msg.isBelowViewport ? '⬇️ BELOW' : 
                        msg.isFullyVisible ? '👁️ VISIBLE' : 
                        msg.isInViewport ? '👀 PARTIAL' : '❌ HIDDEN';
        
        console.log(`${label} Message ${msg.index}${sepLabel} - ${visLabel}`);
        console.log(`   Top: ${msg.topRelative >= 0 ? '+' : ''}${msg.topRelative}px`);
        console.log(`   Text: "${msg.preview}..."`);
        console.log('');
    });
    
    const firstVisible = analysis.messages.find(m => m.isInViewport);
    const oldMsg = analysis.messages.find(m => m.isOldMessage);
    const newMsg = analysis.messages.find(m => m.isNewMessage);
    
    console.log('='.repeat(80));
    console.log('🎯 CRITICAL QUESTIONS ANSWERED:');
    console.log('='.repeat(80) + '\n');
    
    console.log('❓ What is the FIRST visible message at the TOP of the chat?');
    if (firstVisible) {
        console.log(`   ✅ Message ${firstVisible.index}`);
        console.log(`   📝 EXACT TEXT (first 150 chars):`);
        console.log(`   "${firstVisible.text.substring(0, 150).replace(/\s+/g, ' ')}..."`);
    }
    console.log('');
    
    console.log('❓ Is the old "Welcome. I\'m your CoreSync concierge." message HIDDEN above?');
    if (oldMsg) {
        if (oldMsg.isAboveViewport) {
            console.log('   ✅ YES - Hidden above (scrolled out of view)');
            console.log(`   You would need to scroll UP to see it`);
        } else if (oldMsg.isInViewport) {
            console.log('   ❌ NO - It IS visible in the viewport');
        }
        console.log(`   Position: ${oldMsg.topRelative >= 0 ? '+' : ''}${oldMsg.topRelative}px from top`);
    }
    console.log('');
    
    console.log('❓ Or are both messages visible at the same time?');
    const bothVisible = oldMsg?.isInViewport && newMsg?.isInViewport;
    if (bothVisible) {
        console.log('   ✅ YES - Both messages are visible simultaneously');
        console.log(`      Old message: ${oldMsg.isFullyVisible ? 'Fully visible' : 'Partially visible'}`);
        console.log(`      New message: ${newMsg.isFullyVisible ? 'Fully visible' : 'Partially visible'}`);
    } else {
        console.log('   ❌ NO - Only one message is visible');
    }
    console.log('');
    
    console.log('❓ Does it look like a fresh new chat where the newest message is at the top?');
    const looksFresh = !oldMsg?.isInViewport && newMsg?.isInViewport && newMsg.topRelative < 50;
    if (looksFresh) {
        console.log('   ✅ YES - Looks like a fresh chat with new message at top');
    } else if (bothVisible) {
        console.log('   ❌ NO - Shows history (both messages visible)');
    } else {
        console.log('   ⚠️  Ambiguous state');
    }
    console.log('');
    
    // Step 13 - SCROLL UP TEST
    console.log('='.repeat(80));
    console.log('STEP 13: 🔼 SCROLLING UP TEST');
    console.log('='.repeat(80) + '\n');
    
    console.log('Attempting to scroll UP in the chat panel...');
    
    // Try scrolling up by 200px
    await page.locator('#concierge-messages').evaluate(el => {
        const initialScroll = el.scrollTop;
        el.scrollTop = Math.max(0, el.scrollTop - 200);
        const newScroll = el.scrollTop;
        return { initialScroll, newScroll, changed: initialScroll !== newScroll };
    });
    
    await page.waitForTimeout(500); // Wait for scroll to settle
    
    // Step 14 - After scroll screenshot
    console.log('\nSTEP 14: Taking screenshot after scrolling up');
    await page.screenshot({ path: 'ultimate_03_after_scroll.png', fullPage: true });
    console.log('✓ Screenshot saved: ultimate_03_after_scroll.png\n');
    
    // Analyze after scroll
    const afterScroll = await page.locator('#concierge-messages').evaluate(container => {
        const messages = Array.from(container.querySelectorAll('.chat-msg'));
        const containerRect = container.getBoundingClientRect();
        
        return {
            scrollTop: container.scrollTop,
            messages: messages.map(msg => {
                const rect = msg.getBoundingClientRect();
                const topRelative = rect.top - containerRect.top;
                
                return {
                    text: msg.textContent.trim().substring(0, 80).replace(/\s+/g, ' '),
                    isOldMessage: msg.textContent.includes("I'm your CoreSync concierge"),
                    isVisible: topRelative < container.clientHeight && 
                              (rect.bottom - containerRect.top) > 0,
                    topRelative: Math.round(topRelative * 10) / 10
                };
            })
        };
    });
    
    console.log('📊 AFTER SCROLLING UP:');
    console.log(`   New scrollTop: ${afterScroll.scrollTop}px`);
    
    if (afterScroll.scrollTop === analysis.scroll.scrollTop) {
        console.log('   ⚠️  Scroll position UNCHANGED (already at top or no scroll available)');
    } else {
        console.log(`   ✅ Scrolled UP by ${analysis.scroll.scrollTop - afterScroll.scrollTop}px`);
    }
    console.log('');
    
    const oldMsgAfter = afterScroll.messages.find(m => m.isOldMessage);
    console.log('❓ Can you now see the old message above?');
    if (oldMsgAfter?.isVisible) {
        if (analysis.messages.find(m => m.isOldMessage)?.isInViewport) {
            console.log('   ℹ️  Old message was ALREADY visible (no change)');
        } else {
            console.log('   ✅ YES - Now you can see the old message!');
            console.log(`   Position: ${oldMsgAfter.topRelative >= 0 ? '+' : ''}${oldMsgAfter.topRelative}px`);
        }
    } else {
        console.log('   ❌ NO - Still cannot see old message (or it doesn\'t exist)');
    }
    
    console.log('\n' + '='.repeat(80));
    console.log('✅ Ultimate scroll test complete!');
    console.log('   Screenshots saved:');
    console.log('   - ultimate_01_initial.png');
    console.log('   - ultimate_02_critical.png');
    console.log('   - ultimate_03_after_scroll.png');
    console.log('='.repeat(80) + '\n');
});
