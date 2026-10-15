package com.hidarahlab.manote.note.dto;

import java.time.Instant;

/**
 * {@code reminderAt} kosong berarti pengingat dihapus.
 */
public record ReminderRequest(Instant reminderAt) {
}
