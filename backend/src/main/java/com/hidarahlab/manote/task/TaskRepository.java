package com.hidarahlab.manote.task;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRepository extends JpaRepository<TaskItem, Long> {

	List<TaskItem> findByOwnerIdAndDeletedAtIsNullOrderByStartAtAsc(Long ownerId);

	Optional<TaskItem> findByIdAndOwnerIdAndDeletedAtIsNull(Long id, Long ownerId);

	long countByOwnerIdAndDeletedAtIsNullAndDoneAtIsNull(Long ownerId);

	Optional<TaskItem> findFirstByOwnerIdAndDeletedAtIsNullAndDoneAtIsNullOrderByStartAtAsc(Long ownerId);

	// Untuk sinkronisasi: termasuk tugas yang sudah dihapus.
	List<TaskItem> findByOwnerId(Long ownerId);

	List<TaskItem> findByOwnerIdAndChangedAtAfter(Long ownerId, Instant changedAt);

	List<TaskItem> findByOwnerIdAndClientIdIn(Long ownerId, Collection<UUID> clientIds);

}
