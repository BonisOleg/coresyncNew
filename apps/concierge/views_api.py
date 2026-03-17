"""
Concierge REST API views for Flutter.
"""

from __future__ import annotations

import uuid

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.guests.utils import get_guest_from_token

from .engine import process_message
from .flow_engine import process_flow_message
from .models import Conversation, Message
from .serializers import ChatMessageInputSerializer, ConversationSerializer, MessageSerializer
from .utils import is_rate_limited


class ConciergeMessageAPIView(APIView):
    """Send a message to the AI concierge (Flutter / API)."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        serializer = ChatMessageInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        guest = get_guest_from_token(request)
        session_id = serializer.validated_data.get("session_id") or str(uuid.uuid4())
        user_text = serializer.validated_data["message"]
        action = serializer.validated_data.get("action", "")
        flow_step = serializer.validated_data.get("flow_step", "")
        flow_data = serializer.validated_data.get("flow_data", {})

        conversation, created = Conversation.objects.get_or_create(
            session_id=session_id,
            defaults={
                "channel": Conversation.Channel.FLUTTER,
                "guest": guest,
            },
        )

        if guest and not conversation.guest:
            conversation.guest = guest
            conversation.save(update_fields=["guest"])

        Message.objects.create(
            conversation=conversation,
            role=Message.Role.USER,
            content=user_text or flow_step,
            metadata={"action": action, "flow_step": flow_step} if (action or flow_step) else {},
        )

        if is_rate_limited(session_id):
            return Response(
                {"detail": "Too many requests. Please wait a moment."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        if flow_step:
            response_data = process_flow_message(
                conversation, user_text or flow_step, flow_step, flow_data,
            )
        else:
            response_data = process_message(conversation, user_text)

        assistant_msg = Message.objects.create(
            conversation=conversation,
            role=Message.Role.ASSISTANT,
            content=response_data.get("content", ""),
            metadata={
                **response_data.get("metadata", {}),
                "message_type": response_data.get("message_type", "text"),
                "ui_data": response_data.get("ui_data", {}),
            },
        )

        return Response(
            {
                "message": MessageSerializer(assistant_msg).data,
                "session_id": session_id,
                "message_type": response_data.get("message_type", "text"),
                "ui_data": response_data.get("ui_data", {}),
            },
            status=status.HTTP_200_OK,
        )


class ConversationHistoryAPIView(APIView):
    """Retrieve conversation history for the authenticated guest."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        conversations = (
            Conversation.objects.filter(guest=guest)
            .prefetch_related("messages")
            .order_by("-updated_at")[:10]
        )
        serializer = ConversationSerializer(conversations, many=True)
        return Response(serializer.data)
