package com.hidarahlab.manote.kanban.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import com.hidarahlab.manote.kanban.CardStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * @param since penanda dari sinkron sebelumnya; kosong berarti minta semua kerjaan
 * @param boards kerjaan yang berubah di perangkat dan belum sampai ke server
 * @param cards kartu yang berubah di perangkat dan belum sampai ke server
 */
public record KanbanSyncRequest(Instant since,
		@NotNull(message = "Daftar kerjaan wajib dikirim") @Size(max = 500,
				message = "Maksimal 500 kerjaan per sinkron") List<@Valid BoardChange> boards,
		@NotNull(message = "Daftar kartu wajib dikirim") @Size(max = 2000,
				message = "Maksimal 2000 kartu per sinkron") List<@Valid CardChange> cards) {

	public record BoardChange(@NotNull(message = "ID kerjaan wajib dikirim") UUID clientId,
			@NotBlank(message = "Nama kerjaan wajib diisi") @Size(max = 100,
					message = "Nama kerjaan maksimal 100 karakter") String name,
			@NotNull(message = "Waktu ubah wajib dikirim") Instant updatedAt, boolean deleted) {
	}

	public record CardChange(@NotNull(message = "ID kartu wajib dikirim") UUID clientId,
			@NotNull(message = "ID kerjaan kartu wajib dikirim") UUID boardClientId,
			@NotBlank(message = "Judul kartu wajib diisi") @Size(max = 255,
					message = "Judul kartu maksimal 255 karakter") String title,
			@Size(max = 100_000, message = "Deskripsi maksimal 100.000 karakter") String description,
			@NotNull(message = "Kolom kartu wajib diisi") CardStatus status,
			@NotNull(message = "Posisi wajib diisi") @Min(value = 0,
					message = "Posisi tidak boleh negatif") Integer position,
			Instant deadlineAt, Instant doneAt, @NotNull(message = "Waktu ubah wajib dikirim") Instant updatedAt,
			boolean deleted) {
	}

}
