package com.hidarahlab.manote.kanban.dto;

import java.time.Instant;

import com.hidarahlab.manote.kanban.Board;

/**
 * @param totalCards jumlah semua kartu di papan
 * @param doneCards jumlah kartu di kolom Done
 */
public record BoardResponse(Long id, String name, long totalCards, long doneCards, Instant createdAt,
		Instant updatedAt) {

	public static BoardResponse from(Board board, long totalCards, long doneCards) {
		return new BoardResponse(board.getId(), board.getName(), totalCards, doneCards, board.getCreatedAt(),
				board.getUpdatedAt());
	}

}
