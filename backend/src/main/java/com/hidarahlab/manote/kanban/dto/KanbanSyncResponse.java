package com.hidarahlab.manote.kanban.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import com.hidarahlab.manote.kanban.Board;
import com.hidarahlab.manote.kanban.Card;
import com.hidarahlab.manote.kanban.CardStatus;

/**
 * @param cursor kirim balik sebagai {@code since} pada sinkron berikutnya
 * @param boards keadaan terbaru di server untuk kerjaan yang berubah, termasuk yang dihapus
 * @param cards keadaan terbaru di server untuk kartu yang berubah, termasuk yang dihapus
 */
public record KanbanSyncResponse(Instant cursor, List<SyncedBoard> boards, List<SyncedCard> cards) {

	public record SyncedBoard(Long id, UUID clientId, String name, Instant createdAt, Instant updatedAt,
			boolean deleted) {

		public static SyncedBoard from(Board board) {
			return new SyncedBoard(board.getId(), board.getClientId(), board.getName(), board.getCreatedAt(),
					board.getUpdatedAt(), board.isDeleted());
		}

	}

	public record SyncedCard(Long id, UUID clientId, UUID boardClientId, String title, String description,
			CardStatus status, int position, Instant deadlineAt, Instant doneAt, Instant createdAt, Instant updatedAt,
			boolean deleted) {

		public static SyncedCard from(Card card, UUID boardClientId) {
			return new SyncedCard(card.getId(), card.getClientId(), boardClientId, card.getTitle(),
					card.getDescription(), card.getStatus(), card.getPosition(), card.getDeadlineAt(), card.getDoneAt(),
					card.getCreatedAt(), card.getUpdatedAt(), card.isDeleted());
		}

	}

}
