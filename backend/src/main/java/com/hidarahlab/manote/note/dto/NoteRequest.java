package com.hidarahlab.manote.note.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record NoteRequest(
		@NotNull(message = "Judul wajib dikirim") @Size(max = 255, message = "Judul maksimal 255 karakter") String title,
		@NotNull(message = "Isi catatan wajib dikirim") @Size(max = 100_000,
				message = "Isi catatan maksimal 100.000 karakter") String content) {
}
