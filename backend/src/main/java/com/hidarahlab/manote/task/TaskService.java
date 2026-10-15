package com.hidarahlab.manote.task;

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
import com.hidarahlab.manote.note.Note;
import com.hidarahlab.manote.note.NoteRepository;
import com.hidarahlab.manote.task.dto.TaskRequest;
import com.hidarahlab.manote.task.dto.TaskResponse;
import com.hidarahlab.manote.task.dto.TaskSyncRequest;
import com.hidarahlab.manote.task.dto.TaskSyncResponse;
import com.hidarahlab.manote.task.dto.TaskSyncResponse.SyncedTask;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class TaskService {

	private final TaskRepository taskRepository;

	private final NoteRepository noteRepository;

	private final UserRepository userRepository;

	public TaskService(TaskRepository taskRepository, NoteRepository noteRepository,
			UserRepository userRepository) {
		this.taskRepository = taskRepository;
		this.noteRepository = noteRepository;
		this.userRepository = userRepository;
	}

	public List<TaskResponse> list(String userId) {
		return taskRepository.findByOwnerIdAndDeletedAtIsNullOrderByStartAtAsc(ownerId(userId))
			.stream()
			.map(TaskResponse::from)
			.toList();
	}

	@Transactional
	public TaskResponse create(String userId, TaskRequest request) {
		Long ownerId = ownerId(userId);
		// Dibuat dari catatan: catatannya pindah menjadi tugas ini, lalu dihapus.
		Note note = sourceNote(ownerId, request.noteClientId());

		TaskItem task = new TaskItem(ownerId, UUID.randomUUID(), request.title().strip(), request.startAt(),
				TaskItem.now());
		task.update(task.getTitle(), (request.description() != null) ? request.description() : "",
				task.getStartAt(), Boolean.TRUE.equals(request.done()));
		task = taskRepository.save(task);
		if (note != null) {
			note.markDeleted();
		}
		return TaskResponse.from(task);
	}

	@Transactional
	public TaskResponse update(String userId, Long taskId, TaskRequest request) {
		TaskItem task = findOwned(userId, taskId);
		String description = (request.description() != null) ? request.description() : task.getDescription();
		task.update(request.title().strip(), description, request.startAt(), Boolean.TRUE.equals(request.done()));
		return TaskResponse.from(task);
	}

	@Transactional
	public void delete(String userId, Long taskId) {
		// Ditandai terhapus, tidak dibuang, supaya perangkat lain ikut menghapus saat sinkron.
		findOwned(userId, taskId).markDeleted();
	}

	/**
	 * Sinkron dua arah, dengan aturan yang sama seperti catatan: perubahan dengan waktu ubah
	 * paling akhir yang menang.
	 */
	@Transactional
	public TaskSyncResponse sync(String userId, TaskSyncRequest request) {
		Long ownerId = ownerId(userId);
		Map<Long, TaskItem> result = new LinkedHashMap<>();
		applyChanges(ownerId, request.changes()).forEach((task) -> result.put(task.getId(), task));

		List<TaskItem> changedSince = (request.since() != null)
				? taskRepository.findByOwnerIdAndChangedAtAfter(ownerId, request.since())
				: taskRepository.findByOwnerId(ownerId);
		changedSince.forEach((task) -> result.putIfAbsent(task.getId(), task));

		Instant cursor = result.values()
			.stream()
			.map(TaskItem::getChangedAt)
			.max(Comparator.naturalOrder())
			.orElse((request.since() != null) ? request.since() : Instant.EPOCH);
		if (request.since() != null && cursor.isBefore(request.since())) {
			cursor = request.since();
		}
		return new TaskSyncResponse(cursor, result.values().stream().map(SyncedTask::from).toList());
	}

	private List<TaskItem> applyChanges(Long ownerId, List<TaskSyncRequest.Change> changes) {
		if (changes.isEmpty()) {
			return List.of();
		}
		List<UUID> clientIds = changes.stream().map(TaskSyncRequest.Change::clientId).toList();
		Map<UUID, TaskItem> existing = taskRepository.findByOwnerIdAndClientIdIn(ownerId, clientIds)
			.stream()
			.collect(Collectors.toMap(TaskItem::getClientId, Function.identity()));

		Instant now = TaskItem.now();
		for (TaskSyncRequest.Change change : changes) {
			// Jam perangkat yang terlalu maju tidak boleh menang selamanya.
			Instant updatedAt = change.updatedAt().truncatedTo(ChronoUnit.MICROS);
			if (updatedAt.isAfter(now)) {
				updatedAt = now;
			}
			TaskItem task = existing.get(change.clientId());
			if (task == null) {
				if (change.deleted()) {
					continue;
				}
				task = new TaskItem(ownerId, change.clientId(), change.title().strip(), change.startAt(), updatedAt);
				task.applySync(task.getTitle(), description(change), change.startAt(), change.doneAt(), updatedAt,
						false);
				existing.put(change.clientId(), taskRepository.save(task));
			}
			else if (updatedAt.isAfter(task.getUpdatedAt())) {
				task.applySync(change.title().strip(), description(change), change.startAt(), change.doneAt(),
						updatedAt, change.deleted());
			}
		}
		taskRepository.flush();
		return List.copyOf(existing.values());
	}

	private static String description(TaskSyncRequest.Change change) {
		return (change.description() != null) ? change.description() : "";
	}

	private Note sourceNote(Long ownerId, UUID noteClientId) {
		if (noteClientId == null) {
			return null;
		}
		return noteRepository.findByOwnerIdAndClientIdIn(ownerId, List.of(noteClientId))
			.stream()
			.filter((note) -> !note.isDeleted())
			.findFirst()
			.orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND,
					"Catatan belum sampai ke server. Sinkronkan catatan dulu."));
	}

	private TaskItem findOwned(String userId, Long taskId) {
		return taskRepository.findByIdAndOwnerIdAndDeletedAtIsNull(taskId, ownerId(userId))
			.orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "Tugas tidak ditemukan"));
	}

	private Long ownerId(String userId) {
		return userRepository.findByUserId(userId)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID))
			.getId();
	}

}
