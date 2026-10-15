package com.hidarahlab.manote.task.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import com.hidarahlab.manote.task.TaskItem;

/**
 * @param cursor kirim balik sebagai {@code since} pada sinkron berikutnya
 * @param tasks keadaan terbaru di server untuk tugas yang berubah, termasuk yang dihapus
 */
public record TaskSyncResponse(Instant cursor, List<SyncedTask> tasks) {

	public record SyncedTask(Long id, UUID clientId, String title, String description, Instant startAt,
			Instant doneAt,
			Instant createdAt, Instant updatedAt, boolean deleted) {

		public static SyncedTask from(TaskItem task) {
			return new SyncedTask(task.getId(), task.getClientId(), task.getTitle(), task.getDescription(),
					task.getStartAt(), task.getDoneAt(), task.getCreatedAt(), task.getUpdatedAt(), task.isDeleted());
		}

	}

}
