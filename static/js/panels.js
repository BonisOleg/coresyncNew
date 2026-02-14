/**
 * CoreSync Private — Panel Management
 *
 * Handles opening/closing of Explore panel and Concierge panel.
 * No inline JS — all event binding done here.
 */

(function () {
    "use strict";

    var explorePanel = document.getElementById("explore-panel");
    var conciergePanel = document.getElementById("concierge-panel");
    var backdrop = document.getElementById("panel-backdrop");
    var exploreBtn = document.getElementById("explore-btn");
    var wasConciergeClosed = false;

    // --- Helpers: scroll lock & explore button visibility ---

    function updateScrollLock() {
        if (isExploreOpen() || isConciergeOpen()) {
            document.body.classList.add("is-panel-open");
        } else {
            document.body.classList.remove("is-panel-open");
        }
    }

    function updateExploreBtn() {
        if (!exploreBtn) return;
        if (isExploreOpen() || isConciergeOpen()) {
            exploreBtn.classList.add("is-hidden");
        } else if (wasConciergeClosed) {
            // Only show if concierge was closed at least once
            exploreBtn.classList.remove("is-hidden");
        }
    }

    function isExploreOpen() {
        return explorePanel && explorePanel.classList.contains("is-open");
    }

    function isConciergeOpen() {
        return conciergePanel && conciergePanel.classList.contains("is-open");
    }

    // --- Explore panel ---

    function openExplore() {
        if (!explorePanel) return;
        explorePanel.classList.add("is-open");
        if (backdrop) backdrop.classList.add("is-active");
        closeConcierge();
        updateExploreBtn();
        updateScrollLock();
    }

    function closeExplore() {
        if (!explorePanel) return;
        explorePanel.classList.remove("is-open");
        if (backdrop && !isConciergeOpen()) {
            backdrop.classList.remove("is-active");
        }
        updateExploreBtn();
        updateScrollLock();
    }

    // --- Concierge panel ---

    function openConcierge(context) {
        if (!conciergePanel) return;
        
        if (context) {
            // If context provided, reload concierge content with context parameter
            var url = conciergePanel.getAttribute("hx-get");
            if (url) {
                var separator = url.indexOf('?') !== -1 ? '&' : '?';
                var newUrl = url + separator + "context=" + encodeURIComponent(context);
                
                // Use htmx to trigger a request to the new URL
                htmx.ajax('GET', newUrl, {target: '#concierge-content', swap: 'innerHTML'});
            }
        }

        conciergePanel.classList.add("is-open");
        if (backdrop) backdrop.classList.add("is-active");
        closeExplore();
        
        // If context is provided, scrolling will be handled by htmx:afterSwap
        // Otherwise, scroll to bottom
        if (!context) {
            scrollChatToBottom();
        }
        
        updateExploreBtn();
        updateScrollLock();
    }

    function closeConcierge() {
        if (!conciergePanel) return;
        wasConciergeClosed = true;
        conciergePanel.classList.remove("is-open");
        if (backdrop && !isExploreOpen()) {
            backdrop.classList.remove("is-active");
        }
        updateExploreBtn();
        updateScrollLock();
    }

    function scrollChatToBottom() {
        var messages = document.getElementById("concierge-messages");
        if (messages) {
            requestAnimationFrame(function () {
                messages.scrollTop = messages.scrollHeight;
            });
        }
    }

    function collapseOldMessages() {
        var messages = document.getElementById("concierge-messages");
        if (!messages) return;

        var separator = messages.querySelector(".chat-msg--separator");
        if (!separator) {
            scrollChatToBottom();
            return;
        }

        // Collect all messages BEFORE the separator
        var prev = separator.previousElementSibling;
        var oldMessages = [];
        while (prev) {
            oldMessages.push(prev);
            prev = prev.previousElementSibling;
        }

        if (oldMessages.length === 0) return;

        // Hide old messages
        oldMessages.forEach(function (el) {
            el.classList.add("chat-msg--collapsed");
        });

        var revealed = false;

        function revealHistory() {
            if (revealed) return;
            revealed = true;

            // 1. Measure scrollHeight BEFORE reveal
            var heightBefore = messages.scrollHeight;

            // 2. Show all old messages
            oldMessages.forEach(function (el) {
                el.classList.remove("chat-msg--collapsed");
            });

            // 3. Measure scrollHeight AFTER reveal
            var heightAfter = messages.scrollHeight;

            // 4. Compensate scroll so the separator stays in place
            messages.scrollTop = heightAfter - heightBefore;
        }

        // Desktop: wheel / trackpad scroll-up at the top edge
        messages.addEventListener("wheel", function onWheel(e) {
            if (revealed) { messages.removeEventListener("wheel", onWheel); return; }
            if (messages.scrollTop <= 0 && e.deltaY < 0) {
                revealHistory();
                messages.removeEventListener("wheel", onWheel);
            }
        });

        // Mobile: touch pull-down
        var touchStartY = 0;
        messages.addEventListener("touchstart", function onTS(e) {
            if (revealed) { messages.removeEventListener("touchstart", onTS); return; }
            touchStartY = e.touches[0].clientY;
        });
        messages.addEventListener("touchmove", function onTM(e) {
            if (revealed) { messages.removeEventListener("touchmove", onTM); return; }
            if (messages.scrollTop <= 0 && e.touches[0].clientY > touchStartY + 30) {
                revealHistory();
                messages.removeEventListener("touchmove", onTM);
            }
        });
    }

    // --- Event bindings ---

    // Listen for HTMX afterSwap to handle collapse/scroll logic
    document.body.addEventListener('htmx:afterSwap', function(evt) {
        if (evt.detail.target.id === 'concierge-content') {
            collapseOldMessages();
        }
    });

    if (exploreBtn) {
        exploreBtn.addEventListener("click", function () {
            if (isExploreOpen()) {
                closeExplore();
            } else {
                openExplore();
            }
        });
    }

    // Close buttons (delegated)
    document.addEventListener("click", function (e) {
        var target = e.target.closest("[data-action]");
        if (!target) return;

        var action = target.getAttribute("data-action");
        var context = target.getAttribute("data-context");
        
        if (action === "close-explore") closeExplore();
        if (action === "close-concierge") closeConcierge();
        if (action === "open-concierge") openConcierge(context);
        if (action === "open-explore") openExplore();
    });

    // Backdrop click closes all panels
    if (backdrop) {
        backdrop.addEventListener("click", function () {
            closeExplore();
            closeConcierge();
        });
    }

    // ESC key closes panels
    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") {
            closeExplore();
            closeConcierge();
        }
    });

    // --- Auto-open concierge after 4 seconds ---
    setTimeout(function () {
        openConcierge();
    }, 4000);

    // --- Expose for HTMX events ---
    window.CoreSync = window.CoreSync || {};
    window.CoreSync.openConcierge = openConcierge;
    window.CoreSync.closeConcierge = closeConcierge;
    window.CoreSync.openExplore = openExplore;
    window.CoreSync.closeExplore = closeExplore;
    window.CoreSync.scrollChatToBottom = scrollChatToBottom;
})();
