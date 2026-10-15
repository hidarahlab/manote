package com.hidarahlab.manote.note;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NoteRepository extends JpaRepository<Note, Long> {

	List<Note> findByOwnerIdAndDeletedAtIsNullOrderByUpdatedAtDesc(Long ownerId);

	Optional<Note> findByIdAndOwnerIdAndDeletedAtIsNull(Long id, Long ownerId);

	Optional<Note> findFirstByOwnerIdAndDeletedAtIsNullOrderByUpdatedAtDesc(Long ownerId);

	long countByOwnerIdAndDeletedAtIsNull(Long ownerId);

	// Untuk sinkronisasi: termasuk catatan yang sudah dihapus.
	List<Note> findByOwnerId(Long ownerId);

	List<Note> findByOwnerIdAndChangedAtAfter(Long ownerId, Instant changedAt);

	List<Note> findByOwnerIdAndClientIdIn(Long ownerId, Collection<UUID> clientIds);

}
