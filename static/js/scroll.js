/**
 * CoreSync Private — Step-Based Scroll Controller
 *
 * Hijacks native scroll and replaces it with a step-based system.
 * One scroll/swipe/key event = exactly one step, regardless of intensity.
 * Texts fade out, pause, then the next text fades in.
 *
 * All visible content is position:fixed, so scrollTop changes are
 * invisible to the user — they only see opacity transitions.
 */

(function () {
    "use strict";

    /* -----------------------------------------------------------------------
       Timing constants (ms)
       ----------------------------------------------------------------------- */
    var FADE_OUT = 800;
    var PAUSE = 300;
    var FADE_IN = 800;
    var TOUCH_THRESHOLD = 30;

    /* -----------------------------------------------------------------------
       DOM references
       ----------------------------------------------------------------------- */
    var sections = document.querySelectorAll(".room-scroll__section");
    var hero = document.querySelector(".room-hero");
    var allTexts = document.querySelectorAll(".room-scroll__text");

    /* Build ordered list of text elements (null for spacer section) */
    var textForStep = [];
    sections.forEach(function (section) {
        textForStep.push(section.querySelector(".room-scroll__text"));
    });

    var totalSteps = sections.length;

    /* -----------------------------------------------------------------------
       State
       ----------------------------------------------------------------------- */
    var currentStep = 0;
    var isAnimating = false;
    var touchStartY = 0;

    /* -----------------------------------------------------------------------
       Hero entrance animation (unchanged)
       ----------------------------------------------------------------------- */
    if (hero) {
        requestAnimationFrame(function () {
            hero.classList.add("is-loaded");
        });
    }

    if (totalSteps === 0) {
        return;
    }

    /* -----------------------------------------------------------------------
       Helpers
       ----------------------------------------------------------------------- */

    function setScrollPosition(step) {
        var top = step * window.innerHeight;
        window.scrollTo(0, top);
    }

    function isPanelOpen() {
        return document.body.classList.contains("is-panel-open");
    }

    function hideAllTexts() {
        allTexts.forEach(function (el) {
            el.classList.remove("is-visible");
        });
    }

    function showText(step) {
        var text = textForStep[step];
        if (text) {
            text.classList.add("is-visible");
        }
    }

    function hideText(step) {
        var text = textForStep[step];
        if (text) {
            text.classList.remove("is-visible");
        }
    }

    /* -----------------------------------------------------------------------
       Step transition — the core animation sequence
       ----------------------------------------------------------------------- */

    function goToStep(nextStep) {
        if (nextStep < 0 || nextStep >= totalSteps) return;
        if (nextStep === currentStep) return;
        if (isAnimating) return;

        isAnimating = true;

        var leavingStep = currentStep;
        var hasTextLeaving = textForStep[leavingStep] !== null;
        var hasTextEntering = textForStep[nextStep] !== null;

        /* Phase 1: Fade out current text (if any) */
        if (hasTextLeaving) {
            hideText(leavingStep);
        }

        /* If going from hero (step 0) to a text step — hide hero */
        if (leavingStep === 0 && nextStep > 0 && hero) {
            hero.classList.add("is-scrolled");
        }

        /* Phase 2: After fade-out + pause, show new text */
        var delayBeforeIn = hasTextLeaving ? FADE_OUT + PAUSE : PAUSE;

        setTimeout(function () {
            currentStep = nextStep;
            setScrollPosition(nextStep);

            /* If returning to hero (step 0) — show hero */
            if (nextStep === 0 && hero) {
                hero.classList.remove("is-scrolled");
            }

            /* Fade in new text (if any) */
            if (hasTextEntering) {
                showText(nextStep);
            }

            /* Phase 3: Unlock after fade-in completes */
            var unlockDelay = hasTextEntering ? FADE_IN : 300;
            setTimeout(function () {
                isAnimating = false;
            }, unlockDelay);
        }, delayBeforeIn);
    }

    /* -----------------------------------------------------------------------
       Wheel handler (desktop)
       ----------------------------------------------------------------------- */

    window.addEventListener(
        "wheel",
        function (e) {
            if (isPanelOpen()) return;
            e.preventDefault();

            if (isAnimating) return;

            if (e.deltaY > 0) {
                goToStep(currentStep + 1);
            } else if (e.deltaY < 0) {
                goToStep(currentStep - 1);
            }
        },
        { passive: false }
    );

    /* -----------------------------------------------------------------------
       Touch handlers (mobile)
       ----------------------------------------------------------------------- */

    window.addEventListener(
        "touchstart",
        function (e) {
            if (isPanelOpen()) return;
            touchStartY = e.touches[0].clientY;
        },
        { passive: true }
    );

    window.addEventListener(
        "touchmove",
        function (e) {
            if (isPanelOpen()) return;
            e.preventDefault();
        },
        { passive: false }
    );

    window.addEventListener(
        "touchend",
        function (e) {
            if (isPanelOpen()) return;
            if (isAnimating) return;

            var touchEndY = e.changedTouches[0].clientY;
            var deltaY = touchStartY - touchEndY;

            if (Math.abs(deltaY) < TOUCH_THRESHOLD) return;

            if (deltaY > 0) {
                goToStep(currentStep + 1);
            } else {
                goToStep(currentStep - 1);
            }
        },
        { passive: true }
    );

    /* -----------------------------------------------------------------------
       Keyboard handler
       ----------------------------------------------------------------------- */

    document.addEventListener("keydown", function (e) {
        if (isPanelOpen()) return;
        if (isAnimating) return;

        var key = e.key;
        if (
            key === "ArrowDown" ||
            key === " " ||
            key === "PageDown"
        ) {
            e.preventDefault();
            goToStep(currentStep + 1);
        } else if (key === "ArrowUp" || key === "PageUp") {
            e.preventDefault();
            goToStep(currentStep - 1);
        }
    });

    /* -----------------------------------------------------------------------
       Initialise: ensure scroll position matches step 0
       ----------------------------------------------------------------------- */
    setScrollPosition(0);
})();
