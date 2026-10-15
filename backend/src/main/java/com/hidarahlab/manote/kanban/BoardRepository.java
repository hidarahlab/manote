package com.hidarahlab.manote.kanban;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface BoardRepository extends JpaRepository<Board, Long> {

	List<Board> findByOwnerIdAndDeletedAtIsNullOrderByUpdatedAtDesc(Long ownerId);

	Optional<Board> findByIdAndOwnerIdAndDeletedAtIsNull(Long id, Long ownerId);

	// Untuk sinkronisasi: termasuk kerjaan yang sudah dihapus.
	List<Board> findByOwnerId(Long ownerId);

	List<Board> findByOwnerIdAndChangedAtAfter(Long ownerId, Instant changedAt);

	List<Board> findByOwnerIdAndClientIdIn(Long ownerId, Collection<UUID> clientIds);

}
