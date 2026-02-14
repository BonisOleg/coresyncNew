/**
 * CoreSync Private — Concierge Chat Logic
 *
 * Handles HTMX form submission, loading states,
 * and scroll behavior for the chat.
 */

(function () {
    "use strict";

    // --- HTMX event: before send (show loading) ---
    document.addEventListener("htmx:beforeRequest", function (e) {
        var form = e.target.closest("#concierge-form");
        if (!form) return;

        var input = form.querySelector(".concierge-input__field");
        var messages = document.getElementById("concierge-messages");

        if (input && input.value.trim()) {
            // Add user message bubble immediately
            var userMsg = document.createElement("div");
            userMsg.className = "chat-msg chat-msg--user";
            userMsg.textContent = input.value.trim();
            if (messages) messages.appendChild(userMsg);
        }

        // Show loading indicator
        if (messages) {
            var loading = document.createElement("div");
            loading.className = "chat-loading";
            loading.id = "chat-loading";
            loading.innerHTML =
                '<div class="chat-loading__dot"></div>' +
                '<div class="chat-loading__dot"></div>' +
                '<div class="chat-loading__dot"></div>';
            messages.appendChild(loading);
        }

        // Clear input
        if (input) input.value = "";

        // Scroll to bottom
        if (window.CoreSync && window.CoreSync.scrollChatToBottom) {
            window.CoreSync.scrollChatToBottom();
        }
    });

    // --- HTMX event: after response (remove loading, scroll) ---
    document.addEventListener("htmx:afterSwap", function (e) {
        // Remove loading indicator
        var loading = document.getElementById("chat-loading");
        if (loading) loading.remove();

        // Scroll to bottom
        if (window.CoreSync && window.CoreSync.scrollChatToBottom) {
            window.CoreSync.scrollChatToBottom();
        }
    });

    // --- Handle chat action buttons (delegated) ---
    document.addEventListener("click", function (e) {
        var btn = e.target.closest(".chat-btn");
        if (!btn) return;

        var action = btn.getAttribute("data-action");
        var label = btn.textContent.trim();
        if (!action) return;

        // Set action values in the hidden form
        var form = document.getElementById("concierge-form");
        if (!form) return;

        var messageInput = form.querySelector("[name='message']");
        var actionInput = form.querySelector("[name='action']");

        if (messageInput) messageInput.value = label;
        if (actionInput) actionInput.value = action;

        // Trigger HTMX request
        htmx.trigger(form, "submit");
    });
})();
