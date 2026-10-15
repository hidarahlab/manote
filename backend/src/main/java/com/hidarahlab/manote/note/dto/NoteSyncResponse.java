package com.hidarahlab.manote.note.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import com.hidarahlab.manote.note.Note;

/**
 * @param cursor kirim balik sebagai {@code since} pada sinkron berikutnya
 * @param notes keadaan terbaru di server untuk catatan yang berubah, termasuk yang dihapus
 */
public record NoteSyncResponse(Instant cursor, List<SyncedNote> notes) {

	public record SyncedNote(Long id, UUID clientId, String title, String content, Instant createdAt,
			Instant updatedAt, Instant reminderAt, boolean deleted) {

		public static SyncedNote from(Note note) {
			return new SyncedNote(note.getId(), note.getClientId(), note.getTitle(), note.getContent(),
					note.getCreatedAt(), note.getUpdatedAt(), note.getReminderAt(), note.isDeleted());
		}

	}

}
