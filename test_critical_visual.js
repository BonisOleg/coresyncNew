/**
 * CRITICAL VISUAL TEST - Chat Message Position Analysis
 * This test specifically checks the visual layout of messages after reopening concierge
 */

const { test, expect } = require('@playwright/test');
const path = require('path');

test('critical visual test - message position in chat', async ({ page }) => {
    console.log('\n=== CRITICAL VISUAL TEST ===\n');
    
    // Step 1
    console.log('1. Navigating to http://localhost:8000');
    await page.goto('http://localhost:8000');
    
    // Step 2
    console.log('2. Waiting 6 seconds for concierge to auto-open...');
    await page.waitForTimeout(6000);
    
    // Step 3
    console.log('3. Taking screenshot of auto-opened concierge');
    await page.screenshot({ path: 'critical_01_auto_open.png', fullPage: true });
    
    const initialMessages = await page.locator('.chat-msg').allTextContents();
    console.log(`   Initial messages (${initialMessages.length}):`);
    initialMessages.forEach((msg, i) => {
        console.log(`   ${i + 1}. "${msg.trim().substring(0, 50)}..."`);
    });
    
    // Step 4
    console.log('\n4. Closing concierge (clicking X button)');
    await page.click('[data-action="close-concierge"]');
    
    // Step 5
    console.log('5. Waiting 1 second');
    await page.waitForTimeout(1000);
    
    // Step 6
    console.log('6. Clicking burger menu (#explore-btn)');
    await page.click('#explore-btn');
    
    // Step 7
    console.log('7. Waiting 1 second');
    await page.waitForTimeout(1000);
    
    // Step 8
    console.log('8. Clicking "The Experience" link');
    await page.click('text=The Experience');
    
    // Step 9
    console.log('9. Waiting 1 second');
    await page.waitForTimeout(1000);
    
    // Step 10
    console.log('10. Clicking "Talk to the Concierge" button');
    await page.click('[data-action="open-concierge"]');
    
    // Step 11
    console.log('11. Waiting 3 seconds for everything to load...');
    await page.waitForTimeout(3000);
    
    // Step 12 - CRITICAL ANALYSIS
    console.log('\n12. CRITICAL SCREENSHOT & ANALYSIS\n');
    await page.screenshot({ path: 'critical_02_final_state.png', fullPage: true });
    
    // Get all messages
    const finalMessages = await page.locator('.chat-msg').allTextContents();
    console.log(`📊 Total messages visible: ${finalMessages.length}\n`);
    
    // Get messages container and scroll info
    const messagesContainer = page.locator('#concierge-messages');
    const scrollInfo = await messagesContainer.evaluate(el => ({
        scrollTop: el.scrollTop,
        scrollHeight: el.scrollHeight,
        clientHeight: el.clientHeight,
        maxScroll: el.scrollHeight - el.clientHeight
    }));
    
    console.log('📍 SCROLL POSITION:');
    console.log(`   scrollTop: ${scrollInfo.scrollTop}px`);
    console.log(`   scrollHeight: ${scrollInfo.scrollHeight}px`);
    console.log(`   clientHeight: ${scrollInfo.clientHeight}px`);
    console.log(`   maxScroll: ${scrollInfo.maxScroll}px`);
    
    if (scrollInfo.maxScroll > 0) {
        const scrollPercent = (scrollInfo.scrollTop / scrollInfo.maxScroll * 100).toFixed(1);
        console.log(`   Position: ${scrollPercent}% from top (0% = top, 100% = bottom)`);
    } else {
        console.log(`   Position: All content fits in viewport (no scrolling possible)`);
    }
    
    // Analyze each message position
    console.log('\n💬 MESSAGE DETAILS (in DOM order, top to bottom):\n');
    
    const messageDetails = await page.locator('.chat-msg').evaluateAll(messages => {
        return messages.map((msg, index) => {
            const rect = msg.getBoundingClientRect();
            const container = document.getElementById('concierge-messages');
            const containerRect = container.getBoundingClientRect();
            
            return {
                index: index + 1,
                text: msg.textContent.trim().substring(0, 80),
                isSeparator: msg.classList.contains('chat-msg--separator'),
                isUser: msg.classList.contains('chat-msg--user'),
                isAssistant: msg.classList.contains('chat-msg--assistant'),
                topRelativeToContainer: rect.top - containerRect.top,
                isVisibleInViewport: rect.top >= containerRect.top && rect.bottom <= containerRect.bottom,
                rect: {
                    top: Math.round(rect.top),
                    bottom: Math.round(rect.bottom),
                    height: Math.round(rect.height)
                }
            };
        });
    });
    
    messageDetails.forEach(msg => {
        const typeLabel = msg.isSeparator ? '[SEPARATOR]' : msg.isUser ? '[USER]' : '[ASSISTANT]';
        const visibleLabel = msg.isVisibleInViewport ? '👁️ VISIBLE' : '❌ OUT OF VIEW';
        const topPos = msg.topRelativeToContainer >= 0 ? `+${msg.topRelativeToContainer}px` : `${msg.topRelativeToContainer}px`;
        
        console.log(`Message ${msg.index} ${typeLabel} ${visibleLabel}`);
        console.log(`   Position: ${topPos} from container top`);
        console.log(`   Text: "${msg.text}..."`);
        console.log(`   Height: ${msg.rect.height}px\n`);
    });
    
    // Find separator message
    const separatorIndex = messageDetails.findIndex(m => m.isSeparator);
    if (separatorIndex !== -1) {
        const separator = messageDetails[separatorIndex];
        console.log(`🎯 SEPARATOR MESSAGE FOUND at position ${separatorIndex + 1}`);
        console.log(`   This is the NEW contextual message`);
        console.log(`   Position: ${separator.topRelativeToContainer >= 0 ? '+' : ''}${separator.topRelativeToContainer}px from container top`);
        console.log(`   Visible: ${separator.isVisibleInViewport ? 'YES ✅' : 'NO ❌'}`);
        
        if (separatorIndex > 0) {
            console.log(`\n   ⚠️  OLD MESSAGE(S) EXIST ABOVE THE SEPARATOR`);
            console.log(`   There are ${separatorIndex} message(s) before the separator`);
        } else {
            console.log(`\n   ✅ SEPARATOR IS THE FIRST MESSAGE (clean state)`);
        }
    }
    
    // Answer the critical questions
    console.log('\n' + '='.repeat(70));
    console.log('🔍 CRITICAL QUESTIONS ANSWERED:');
    console.log('='.repeat(70));
    
    const newestMessage = messageDetails[messageDetails.length - 1];
    const hasExploreText = finalMessages.some(msg => 
        msg.includes('explore CoreSync Private') || msg.includes('book your visit')
    );
    
    console.log('\n❓ Is the NEWEST message (with "explore CoreSync Private, book your visit")');
    console.log('   visible at the TOP of the chat area?');
    
    if (separatorIndex !== -1) {
        const separator = messageDetails[separatorIndex];
        if (separator.topRelativeToContainer <= 50 && separator.isVisibleInViewport) {
            console.log('   ✅ YES - The new message is at/near the TOP and VISIBLE');
        } else if (separator.isVisibleInViewport) {
            console.log('   ⚠️  PARTIALLY - The new message is visible but not at the very top');
            console.log(`      (Position: ${separator.topRelativeToContainer}px from top)`);
        } else {
            console.log('   ❌ NO - The new message exists but is scrolled out of view');
        }
    } else {
        console.log('   ❓ Cannot determine - no separator found');
    }
    
    console.log('\n❓ Or is it at the BOTTOM with old messages visible above it?');
    if (separatorIndex !== -1 && separatorIndex < messageDetails.length - 1) {
        console.log('   ❌ NO - The separator is NOT the last message');
        console.log(`      (There are ${messageDetails.length - separatorIndex - 1} messages after it)`);
    } else if (separatorIndex === messageDetails.length - 1) {
        console.log('   ✅ YES - The new message IS at the bottom');
        if (separatorIndex > 0) {
            console.log(`      AND there are ${separatorIndex} old message(s) visible above it`);
        }
    }
    
    console.log('\n❓ Can you see TWO different welcome messages at the same time?');
    const welcomeMessages = finalMessages.filter(msg => 
        msg.toLowerCase().includes('welcome')
    );
    if (welcomeMessages.length >= 2) {
        console.log(`   ✅ YES - Found ${welcomeMessages.length} messages containing "welcome"`);
        welcomeMessages.forEach((msg, i) => {
            console.log(`      ${i + 1}. "${msg.trim().substring(0, 60)}..."`);
        });
    } else {
        console.log(`   ❌ NO - Only ${welcomeMessages.length} welcome message found`);
    }
    
    console.log('\n❓ Does it look like a fresh/new chat, or does it show history?');
    if (finalMessages.length === 1) {
        console.log('   ✅ FRESH CHAT - Only 1 message visible');
    } else if (separatorIndex === 0) {
        console.log('   ✅ FRESH CHAT - Separator is first message (history hidden/cleared)');
    } else if (separatorIndex > 0) {
        console.log(`   ❌ SHOWS HISTORY - ${separatorIndex} old message(s) visible before separator`);
    } else {
        console.log(`   ❌ SHOWS HISTORY - Multiple messages (${finalMessages.length}) visible`);
    }
    
    console.log('\n' + '='.repeat(70));
    console.log('\n✅ Critical visual test complete!');
    console.log('   Screenshots: critical_01_auto_open.png, critical_02_final_state.png');
});
