package com.hidarahlab.manote.note.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * @param since penanda dari sinkron sebelumnya; kosong berarti minta semua catatan
 * @param changes perubahan di perangkat yang belum sampai ke server
 */
public record NoteSyncRequest(Instant since,
		@NotNull(message = "Daftar perubahan wajib dikirim") @Size(max = 500,
				message = "Maksimal 500 perubahan per sinkron") List<@Valid Change> changes) {

	public record Change(@NotNull(message = "ID catatan wajib dikirim") UUID clientId,
			@NotNull(message = "Judul wajib dikirim") @Size(max = 255,
					message = "Judul maksimal 255 karakter") String title,
			@NotNull(message = "Isi catatan wajib dikirim") @Size(max = 100_000,
					message = "Isi catatan maksimal 100.000 karakter") String content,
			Instant reminderAt, @NotNull(message = "Waktu ubah wajib dikirim") Instant updatedAt, boolean deleted) {
	}

}
