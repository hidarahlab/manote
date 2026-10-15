package com.hidarahlab.manote.kanban.dto;

import java.time.Instant;
import java.util.UUID;

import com.hidarahlab.manote.kanban.Card;
import com.hidarahlab.manote.kanban.CardStatus;

public record CardResponse(Long id, UUID clientId, Long boardId, String title, String description, CardStatus status, int position,
		Long noteId, Instant deadlineAt, Instant doneAt, Instant createdAt, Instant updatedAt) {

	public static CardResponse from(Card card) {
		return new CardResponse(card.getId(), card.getClientId(), card.getBoardId(), card.getTitle(), card.getDescription(),
				card.getStatus(), card.getPosition(), card.getNoteId(), card.getDeadlineAt(), card.getDoneAt(), card.getCreatedAt(),
				card.getUpdatedAt());
	}

}
