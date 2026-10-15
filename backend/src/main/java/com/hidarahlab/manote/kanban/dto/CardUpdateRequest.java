package com.hidarahlab.manote.kanban.dto;

import java.time.Instant;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * @param deadlineAt tenggat kartu; kosong berarti tenggat dihapus
 */
public record CardUpdateRequest(
		@NotBlank(message = "Judul kartu wajib diisi") @Size(max = 255,
				message = "Judul kartu maksimal 255 karakter") String title,
		@NotNull(message = "Deskripsi wajib dikirim") @Size(max = 100_000,
				message = "Deskripsi maksimal 100.000 karakter") String description,
		Instant deadlineAt) {
}
