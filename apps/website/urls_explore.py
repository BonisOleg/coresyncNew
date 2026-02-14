"""HTMX partial endpoints for the Explore panel."""

from django.urls import path

from . import views

app_name = "explore"

urlpatterns = [
    path("panel/", views.explore_panel, name="panel"),
    path("experience/", views.explore_experience, name="experience"),
    path("membership/", views.explore_membership, name="membership"),
    path("backyard/", views.explore_backyard, name="backyard"),
    path("story/", views.explore_story, name="story"),
    path("contact/", views.explore_contact, name="contact"),
]
