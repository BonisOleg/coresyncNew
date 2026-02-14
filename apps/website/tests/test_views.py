"""Tests for website views."""

import pytest
from django.test import Client


@pytest.mark.django_db
class TestRoomView:
    def test_room_returns_200(self):
        client = Client()
        response = client.get("/")
        assert response.status_code == 200

    def test_room_contains_coresync(self):
        client = Client()
        response = client.get("/")
        content = response.content.decode()
        assert "CoreSync" in content

    def test_healthcheck(self):
        client = Client()
        response = client.get("/healthz/")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"
