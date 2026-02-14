/**
 * CoreSync Private — Mood & Dynamic Background Video
 *
 * Applies mood-specific CSS classes to the body based on time of day.
 * Dynamically switches background video based on mood.
 * Video URLs are passed via data-* attributes on the video element (from Django template).
 */

(function () {
    "use strict";

    var videoElement = document.getElementById("background-video");

    /* Read video URLs from data-* attributes (set by Django template in room.html) */
    var videoSources = {
        morning: videoElement ? videoElement.getAttribute("data-video-morning") : "",
        midday: videoElement ? videoElement.getAttribute("data-video-midday") : "",
        night: videoElement ? videoElement.getAttribute("data-video-night") : "",
    };

    function setVideoSource(moodClass) {
        var newSource = '';
        if (moodClass === 'mood-morning') {
            newSource = videoSources.morning;
        } else if (moodClass === 'mood-midday') {
            newSource = videoSources.midday;
        } else if (moodClass === 'mood-night') {
            newSource = videoSources.night;
        }

        if (videoElement && newSource) {
            var currentSource = videoElement.getAttribute("src");
            if (currentSource !== newSource) {
                /* Fade out current video, change source, then fade in new video */
                videoElement.style.opacity = '0';
                setTimeout(function() {
                    videoElement.src = newSource;
                    videoElement.load();
                    videoElement.play().catch(function(error) {
                        console.warn("Autoplay prevented:", error);
                    });
                    videoElement.style.opacity = '1';
                }, 500); /* Small delay to allow fade out to start */
            }
        }
    }

    /* Apply mood class based on current time */
    function applyMoodClass() {
        var now = new Date();
        var hours = now.getHours();
        var moodClass = '';

        if (hours >= 6 && hours < 12) {
            moodClass = 'mood-morning';
        } else if (hours >= 12 && hours < 18) {
            moodClass = 'mood-midday';
        } else {
            moodClass = 'mood-night';
        }

        /* Only update if mood class changes */
        if (!document.body.classList.contains(moodClass)) {
            /* Remove only mood-specific classes, preserve other classes like 'is-panel-open' */
            document.body.classList.remove('mood-morning', 'mood-midday', 'mood-night');
            document.body.classList.add(moodClass);
            setVideoSource(moodClass); /* Update video source based on new mood */
        }
    }

    /* Initial call to set mood and video */
    applyMoodClass();

    /* Update mood and video every 5 minutes */
    setInterval(applyMoodClass, 1000 * 60 * 5);

})();
