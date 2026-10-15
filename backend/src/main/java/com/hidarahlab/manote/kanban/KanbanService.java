package com.hidarahlab.manote.kanban;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;
import com.hidarahlab.manote.kanban.dto.BoardDetailResponse;
import com.hidarahlab.manote.kanban.dto.BoardRequest;
import com.hidarahlab.manote.kanban.dto.BoardResponse;
import com.hidarahlab.manote.kanban.dto.CardCreateRequest;
import com.hidarahlab.manote.kanban.dto.CardMoveRequest;
import com.hidarahlab.manote.kanban.dto.CardResponse;
import com.hidarahlab.manote.kanban.dto.CardUpdateRequest;
import com.hidarahlab.manote.note.Note;
import com.hidarahlab.manote.note.NoteRepository;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class KanbanService {

	private static final Comparator<Card> BOARD_ORDER = Comparator.comparing(Card::getStatus)
		.thenComparingInt(Card::getPosition);

	private final BoardRepository boardRepository;

	private final CardRepository cardRepository;

	private final NoteRepository noteRepository;

	private final UserRepository userRepository;

	public KanbanService(BoardRepository boardRepository, CardRepository cardRepository,
			NoteRepository noteRepository, UserRepository userRepository) {
		this.boardRepository = boardRepository;
		this.cardRepository = cardRepository;
		this.noteRepository = noteRepository;
		this.userRepository = userRepository;
	}

	// Papan

	public List<BoardResponse> listBoards(String userId) {
		List<Board> boards = boardRepository.findByOwnerIdAndDeletedAtIsNullOrderByUpdatedAtDesc(ownerId(userId));
		if (boards.isEmpty()) {
			return List.of();
		}
		Map<Long, Map<CardStatus, Long>> counts = new HashMap<>();
		for (Object[] row : cardRepository.countByBoardAndStatus(boards.stream().map(Board::getId).toList())) {
			counts.computeIfAbsent((Long) row[0], (id) -> new EnumMap<>(CardStatus.class))
				.put((CardStatus) row[1], (Long) row[2]);
		}
		return boards.stream().map((board) -> {
			Map<CardStatus, Long> byStatus = counts.getOrDefault(board.getId(), Map.of());
			long total = byStatus.values().stream().mapToLong(Long::longValue).sum();
			return BoardResponse.from(board, total, byStatus.getOrDefault(CardStatus.DONE, 0L));
		}).toList();
	}

	public BoardDetailResponse getBoard(String userId, Long boardId) {
		Board board = findBoard(userId, boardId);
		List<CardResponse> cards = cardRepository.findByBoardIdAndDeletedAtIsNull(boardId)
			.stream()
			.sorted(BOARD_ORDER)
			.map(CardResponse::from)
			.toList();
		return new BoardDetailResponse(board.getId(), board.getName(), cards);
	}

	@Transactional
	public BoardResponse createBoard(String userId, BoardRequest request) {
		Board board = boardRepository.save(new Board(ownerId(userId), request.name().strip()));
		return BoardResponse.from(board, 0, 0);
	}

	@Transactional
	public BoardResponse renameBoard(String userId, Long boardId, BoardRequest request) {
		Board board = findBoard(userId, boardId);
		board.rename(request.name().strip());
		List<Card> cards = cardRepository.findByBoardIdAndDeletedAtIsNull(boardId);
		long done = cards.stream().filter((card) -> card.getStatus() == CardStatus.DONE).count();
		return BoardResponse.from(board, cards.size(), done);
	}

	@Transactional
	public void deleteBoard(String userId, Long boardId) {
		// Ditandai terhapus beserta kartunya, supaya perangkat lain ikut menghapus saat sinkron.
		Board board = findBoard(userId, boardId);
		cardRepository.findByBoardIdAndDeletedAtIsNull(boardId).forEach(Card::markDeleted);
		board.markDeleted();
	}

	// Kartu

	@Transactional
	public CardResponse createCard(String userId, Long boardId, CardCreateRequest request) {
		Board board = findBoard(userId, boardId);
		CardStatus status = (request.status() != null) ? request.status() : CardStatus.BACKLOG;
		int position = cardRepository.findByBoardIdAndStatusAndDeletedAtIsNullOrderByPositionAsc(boardId, status).size();
		String description = (request.description() != null) ? request.description() : "";

		// Dibuat dari catatan: catatannya pindah menjadi kartu ini. Pengingatnya menjadi tenggat,
		// lalu catatannya dihapus.
		Note note = sourceNote(board.getOwnerId(), request);
		Instant deadlineAt = request.deadlineAt();
		if (deadlineAt == null && note != null) {
			deadlineAt = note.getReminderAt();
		}
		Card card = cardRepository.save(new Card(boardId, request.title().strip(), description, status, position,
				(note != null) ? note.getId() : null, deadlineAt));
		if (note != null) {
			note.markDeleted();
		}
		board.touch();
		return CardResponse.from(card);
	}

	@Transactional
	public CardResponse updateCard(String userId, Long cardId, CardUpdateRequest request) {
		Card card = findCard(userId, cardId);
		card.update(request.title().strip(), request.description(), request.deadlineAt());
		touchBoard(card);
		return CardResponse.from(card);
	}

	/**
	 * Memindahkan kartu ke kolom dan posisi tujuan, lalu merapikan urutan kolom asal dan tujuan.
	 */
	@Transactional
	public CardResponse moveCard(String userId, Long cardId, CardMoveRequest request) {
		Card card = findCard(userId, cardId);
		CardStatus from = card.getStatus();
		CardStatus to = request.status();

		List<Card> target = new ArrayList<>(
				cardRepository.findByBoardIdAndStatusAndDeletedAtIsNullOrderByPositionAsc(card.getBoardId(), to));
		target.removeIf((other) -> other.getId().equals(card.getId()));
		target.add(Math.min(request.position(), target.size()), card);
		renumber(target, to);

		if (from != to) {
			List<Card> source = new ArrayList<>(
					cardRepository.findByBoardIdAndStatusAndDeletedAtIsNullOrderByPositionAsc(card.getBoardId(), from));
			source.removeIf((other) -> other.getId().equals(card.getId()));
			renumber(source, from);
		}
		touchBoard(card);
		return CardResponse.from(card);
	}

	@Transactional
	public void deleteCard(String userId, Long cardId) {
		Card card = findCard(userId, cardId);
		List<Card> remaining = new ArrayList<>(
				cardRepository.findByBoardIdAndStatusAndDeletedAtIsNullOrderByPositionAsc(card.getBoardId(), card.getStatus()));
		remaining.removeIf((other) -> other.getId().equals(card.getId()));
		renumber(remaining, card.getStatus());
		touchBoard(card);
		card.markDeleted();
	}

	private static void renumber(List<Card> cards, CardStatus status) {
		for (int index = 0; index < cards.size(); index++) {
			cards.get(index).place(status, index);
		}
	}

	private Note sourceNote(Long ownerId, CardCreateRequest request) {
		if (request.noteClientId() == null) {
			return null;
		}
		return noteRepository.findByOwnerIdAndClientIdIn(ownerId, List.of(request.noteClientId()))
			.stream()
			.filter((note) -> !note.isDeleted())
			.findFirst()
			.orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND,
					"Catatan belum sampai ke server. Sinkronkan catatan dulu."));
	}

	private void touchBoard(Card card) {
		boardRepository.findById(card.getBoardId()).ifPresent(Board::touch);
	}

	private Board findBoard(String userId, Long boardId) {
		return boardRepository.findByIdAndOwnerIdAndDeletedAtIsNull(boardId, ownerId(userId))
			.orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "Kerjaan tidak ditemukan"));
	}

	private Card findCard(String userId, Long cardId) {
		return cardRepository.findOwned(cardId, ownerId(userId))
			.orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "Kartu tidak ditemukan"));
	}

	private Long ownerId(String userId) {
		return userRepository.findByUserId(userId)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID))
			.getId();
	}

}
