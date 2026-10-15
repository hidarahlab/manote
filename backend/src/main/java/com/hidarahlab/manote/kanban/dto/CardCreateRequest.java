package com.hidarahlab.manote.kanban.dto;

import java.time.Instant;
import java.util.UUID;

import com.hidarahlab.manote.kanban.CardStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * @param status kolom tujuan; kosong berarti Backlog
 * @param noteClientId ID catatan asal ({@code clientId}), jika kartu dibuat dari catatan.
 * Catatan itu dipindahkan: pengingatnya menjadi tenggat kartu, lalu catatannya dihapus.
 * @param deadlineAt tenggat kartu; jika kosong dan kartu dibuat dari catatan, dipakai pengingat
 * catatannya
 */
public record CardCreateRequest(
		@NotBlank(message = "Judul kartu wajib diisi") @Size(max = 255,
				message = "Judul kartu maksimal 255 karakter") String title,
		@Size(max = 100_000, message = "Deskripsi maksimal 100.000 karakter") String description, CardStatus status,
		UUID noteClientId, Instant deadlineAt) {
}
