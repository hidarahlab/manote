package com.hidarahlab.manote.task.dto;

import java.time.Instant;
import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * @param description keterangan; kosong saat mengubah berarti keterangan lama dipertahankan
 * @param done kosong dianggap belum selesai
 * @param noteClientId hanya saat membuat: ID catatan asal ({@code clientId}). Catatan itu
 * dipindahkan menjadi tugas ini, lalu dihapus.
 */
public record TaskRequest(
		@NotBlank(message = "Nama tugas wajib diisi") @Size(max = 255,
				message = "Nama tugas maksimal 255 karakter") String title,
		@Size(max = 100_000, message = "Keterangan maksimal 100.000 karakter") String description,
		@NotNull(message = "Waktu mulai wajib diisi") Instant startAt, Boolean done, UUID noteClientId) {
}
