package com.hidarahlab.manote.task.dto;

import java.time.Instant;
import java.util.UUID;

import com.hidarahlab.manote.task.TaskItem;

public record TaskResponse(Long id, UUID clientId, String title, String description, Instant startAt,
		boolean done, Instant doneAt,
		Instant createdAt, Instant updatedAt) {

	public static TaskResponse from(TaskItem task) {
		return new TaskResponse(task.getId(), task.getClientId(), task.getTitle(), task.getDescription(), task.getStartAt(),
				task.isDone(),
				task.getDoneAt(), task.getCreatedAt(), task.getUpdatedAt());
	}

}
