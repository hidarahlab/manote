package com.hidarahlab.manote.note.dto;

import java.time.Instant;
import java.util.UUID;

import com.hidarahlab.manote.note.Note;

public record NoteResponse(Long id, UUID clientId, String title, String content, Instant createdAt, Instant updatedAt,
		Instant reminderAt) {

	public static NoteResponse from(Note note) {
		return new NoteResponse(note.getId(), note.getClientId(), note.getTitle(), note.getContent(), note.getCreatedAt(),
				note.getUpdatedAt(), note.getReminderAt());
	}

}
