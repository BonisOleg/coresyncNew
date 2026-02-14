"""
Development settings for CoreSync Private.
"""

from .base import *  # noqa: F401, F403

DEBUG = True

# Use console email backend during development
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Use local file storage for media during development (no Cloudinary required)
DEFAULT_FILE_STORAGE = "django.core.files.storage.FileSystemStorage"

# Relax throttling for dev
REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {  # noqa: F405
    "anon": "600/minute",
    "user": "1200/minute",
}
