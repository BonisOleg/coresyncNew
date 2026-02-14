"""Serializers for concierge chat messages."""

from __future__ import annotations

from rest_framework import serializers

from .models import Conversation, Message


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ("id", "role", "content", "metadata", "created_at")
        read_only_fields = ("id", "role", "created_at")


class ConversationSerializer(serializers.ModelSerializer):
    messages = MessageSerializer(many=True, read_only=True)

    class Meta:
        model = Conversation
        fields = ("id", "channel", "status", "context", "messages", "created_at", "updated_at")


class ChatMessageInputSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=2000)
    session_id = serializers.CharField(max_length=255, required=False)
    action = serializers.CharField(max_length=50, required=False, allow_blank=True)
