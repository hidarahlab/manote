package com.hidarahlab.manote.kanban;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;
import com.hidarahlab.manote.kanban.dto.KanbanSyncRequest;
import com.hidarahlab.manote.kanban.dto.KanbanSyncResponse;
import com.hidarahlab.manote.kanban.dto.KanbanSyncResponse.SyncedBoard;
import com.hidarahlab.manote.kanban.dto.KanbanSyncResponse.SyncedCard;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sinkronisasi kerjaan dan kartu dua arah, dengan aturan yang sama seperti catatan: perubahan
 * dengan waktu ubah paling akhir yang menang.
 */
@Service
public class KanbanSyncService {

	private final BoardRepository boardRepository;

	private final CardRepository cardRepository;

	private final UserRepository userRepository;

	public KanbanSyncService(BoardRepository boardRepository, CardRepository cardRepository,
			UserRepository userRepository) {
		this.boardRepository = boardRepository;
		this.cardRepository = cardRepository;
		this.userRepository = userRepository;
	}

	@Transactional
	public KanbanSyncResponse sync(String userId, KanbanSyncRequest request) {
		Long ownerId = userRepository.findByUserId(userId)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID))
			.getId();
		Instant since = request.since();

		// Kerjaan lebih dulu, karena kartu baru bisa merujuk kerjaan yang baru dibuat.
		Map<Long, Board> boards = new LinkedHashMap<>();
		applyBoards(ownerId, request.boards()).forEach((board) -> boards.put(board.getId(), board));
		Map<Long, Card> cards = new LinkedHashMap<>();
		applyCards(ownerId, request.cards()).forEach((card) -> cards.put(card.getId(), card));

		((since != null) ? boardRepository.findByOwnerIdAndChangedAtAfter(ownerId, since)
				: boardRepository.findByOwnerId(ownerId))
			.forEach((board) -> boards.putIfAbsent(board.getId(), board));
		((since != null) ? cardRepository.findOwnedChangedAfter(ownerId, since) : cardRepository.findAllOwned(ownerId))
			.forEach((card) -> cards.putIfAbsent(card.getId(), card));

		Instant cursor = Stream
			.concat(boards.values().stream().map(Board::getChangedAt), cards.values().stream().map(Card::getChangedAt))
			.max(Instant::compareTo)
			.orElse((since != null) ? since : Instant.EPOCH);
		if (since != null && cursor.isBefore(since)) {
			cursor = since;
		}

		Map<Long, UUID> boardClientIds = boardRepository.findByOwnerId(ownerId)
			.stream()
			.collect(Collectors.toMap(Board::getId, Board::getClientId));
		return new KanbanSyncResponse(cursor, boards.values().stream().map(SyncedBoard::from).toList(),
				cards.values()
					.stream()
					.map((card) -> SyncedCard.from(card, boardClientIds.get(card.getBoardId())))
					.toList());
	}

	private List<Board> applyBoards(Long ownerId, List<KanbanSyncRequest.BoardChange> changes) {
		if (changes.isEmpty()) {
			return List.of();
		}
		Map<UUID, Board> existing = boardRepository
			.findByOwnerIdAndClientIdIn(ownerId, changes.stream().map(KanbanSyncRequest.BoardChange::clientId).toList())
			.stream()
			.collect(Collectors.toMap(Board::getClientId, Function.identity()));

		for (KanbanSyncRequest.BoardChange change : changes) {
			Instant updatedAt = clamp(change.updatedAt());
			Board board = existing.get(change.clientId());
			if (board == null) {
				if (change.deleted()) {
					continue;
				}
				board = boardRepository.save(new Board(ownerId, change.clientId(), change.name().strip(), updatedAt));
				existing.put(change.clientId(), board);
			}
			else if (updatedAt.isAfter(board.getUpdatedAt())) {
				board.applySync(change.name().strip(), updatedAt, change.deleted());
				if (change.deleted()) {
					// Kerjaan dihapus beserta kartunya.
					cardRepository.findByBoardId(board.getId())
						.stream()
						.filter((card) -> !card.isDeleted())
						.forEach(Card::markDeleted);
				}
			}
		}
		boardRepository.flush();
		return List.copyOf(existing.values());
	}

	private List<Card> applyCards(Long ownerId, List<KanbanSyncRequest.CardChange> changes) {
		if (changes.isEmpty()) {
			return List.of();
		}
		Map<UUID, Card> existing = cardRepository
			.findOwnedByClientIds(ownerId, changes.stream().map(KanbanSyncRequest.CardChange::clientId).toList())
			.stream()
			.collect(Collectors.toMap(Card::getClientId, Function.identity()));
		Map<UUID, Board> boards = boardRepository
			.findByOwnerIdAndClientIdIn(ownerId,
					changes.stream().map(KanbanSyncRequest.CardChange::boardClientId).filter(Objects::nonNull).toList())
			.stream()
			.collect(Collectors.toMap(Board::getClientId, Function.identity()));

		for (KanbanSyncRequest.CardChange change : changes) {
			Instant updatedAt = clamp(change.updatedAt());
			String description = (change.description() != null) ? change.description() : "";
			Card card = existing.get(change.clientId());
			if (card == null) {
				Board board = boards.get(change.boardClientId());
				// Kartu untuk kerjaan yang tidak ada atau sudah dihapus tidak dibuat.
				if (change.deleted() || board == null || board.isDeleted()) {
					continue;
				}
				card = cardRepository.save(new Card(board.getId(), change.clientId(), change.title().strip(),
						description, change.status(), change.position(), change.deadlineAt(), updatedAt));
				card.setDoneAtFromSync(change.doneAt());
				existing.put(change.clientId(), card);
			}
			else if (updatedAt.isAfter(card.getUpdatedAt())) {
				card.applySync(change.title().strip(), description, change.status(), change.position(),
						change.deadlineAt(), change.doneAt(), updatedAt, change.deleted());
			}
		}
		cardRepository.flush();
		return List.copyOf(existing.values());
	}

	// Jam perangkat yang terlalu maju tidak boleh menang selamanya.
	private static Instant clamp(Instant updatedAt) {
		Instant now = Board.now();
		Instant truncated = updatedAt.truncatedTo(ChronoUnit.MICROS);
		return truncated.isAfter(now) ? now : truncated;
	}

}
