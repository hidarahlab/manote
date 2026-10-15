package com.hidarahlab.manote.note;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;
import com.hidarahlab.manote.note.dto.NoteSyncRequest;
import com.hidarahlab.manote.note.dto.NoteSyncResponse;
import com.hidarahlab.manote.note.dto.NoteSyncResponse.SyncedNote;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sinkronisasi catatan dua arah: menerima perubahan dari perangkat, lalu mengembalikan
 * keadaan terbaru di server. Jika catatan yang sama berubah di dua tempat, perubahan
 * dengan waktu ubah paling akhir yang menang.
 */
@Service
public class NoteSyncService {

	private final NoteRepository noteRepository;

	private final UserRepository userRepository;

	public NoteSyncService(NoteRepository noteRepository, UserRepository userRepository) {
		this.noteRepository = noteRepository;
		this.userRepository = userRepository;
	}

	@Transactional
	public NoteSyncResponse sync(String userId, NoteSyncRequest request) {
		Long ownerId = userRepository.findByUserId(userId)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID))
			.getId();

		Map<Long, Note> result = new LinkedHashMap<>();
		applyChanges(ownerId, request.changes()).forEach((note) -> result.put(note.getId(), note));

		List<Note> changedSince = (request.since() != null)
				? noteRepository.findByOwnerIdAndChangedAtAfter(ownerId, request.since())
				: noteRepository.findByOwnerId(ownerId);
		changedSince.forEach((note) -> result.putIfAbsent(note.getId(), note));

		Instant cursor = result.values()
			.stream()
			.map(Note::getChangedAt)
			.max(Comparator.naturalOrder())
			.orElse((request.since() != null) ? request.since() : Instant.EPOCH);
		// Jangan pernah memundurkan penanda milik perangkat.
		if (request.since() != null && cursor.isBefore(request.since())) {
			cursor = request.since();
		}
		return new NoteSyncResponse(cursor, result.values().stream().map(SyncedNote::from).toList());
	}

	/**
	 * Mengembalikan semua catatan yang disebut di {@code changes}, baik perubahannya
	 * diterima maupun kalah dari versi server, supaya perangkat menerima keadaan akhirnya.
	 */
	private List<Note> applyChanges(Long ownerId, List<NoteSyncRequest.Change> changes) {
		if (changes.isEmpty()) {
			return List.of();
		}
		List<UUID> clientIds = changes.stream().map(NoteSyncRequest.Change::clientId).toList();
		Map<UUID, Note> existing = noteRepository.findByOwnerIdAndClientIdIn(ownerId, clientIds)
			.stream()
			.collect(Collectors.toMap(Note::getClientId, Function.identity()));

		Instant now = Note.now();
		for (NoteSyncRequest.Change change : changes) {
			// Jam perangkat yang terlalu maju tidak boleh menang selamanya.
			Instant updatedAt = change.updatedAt().truncatedTo(ChronoUnit.MICROS);
			if (updatedAt.isAfter(now)) {
				updatedAt = now;
			}
			Note note = existing.get(change.clientId());
			if (note == null) {
				if (change.deleted()) {
					continue;
				}
				note = new Note(ownerId, change.clientId(), change.title(), change.content(), updatedAt);
				if (change.reminderAt() != null) {
					note.applySync(change.title(), change.content(), change.reminderAt(), updatedAt, false);
				}
				existing.put(change.clientId(), noteRepository.save(note));
			}
			else if (updatedAt.isAfter(note.getUpdatedAt())) {
				note.applySync(change.title(), change.content(), change.reminderAt(), updatedAt, change.deleted());
			}
		}
		noteRepository.flush();
		return List.copyOf(existing.values());
	}

}
