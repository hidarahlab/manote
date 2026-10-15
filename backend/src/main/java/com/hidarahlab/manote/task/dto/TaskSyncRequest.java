package com.hidarahlab.manote.task.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * @param since penanda dari sinkron sebelumnya; kosong berarti minta semua tugas
 * @param changes perubahan di perangkat yang belum sampai ke server
 */
public record TaskSyncRequest(Instant since,
		@NotNull(message = "Daftar perubahan wajib dikirim") @Size(max = 500,
				message = "Maksimal 500 perubahan per sinkron") List<@Valid Change> changes) {

	public record Change(@NotNull(message = "ID tugas wajib dikirim") UUID clientId,
			@NotBlank(message = "Nama tugas wajib diisi") @Size(max = 255,
					message = "Nama tugas maksimal 255 karakter") String title,
			@Size(max = 100_000, message = "Keterangan maksimal 100.000 karakter") String description,
			@NotNull(message = "Waktu mulai wajib diisi") Instant startAt, Instant doneAt,
			@NotNull(message = "Waktu ubah wajib dikirim") Instant updatedAt, boolean deleted) {
	}

}
