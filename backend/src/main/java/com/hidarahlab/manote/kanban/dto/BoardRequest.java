package com.hidarahlab.manote.kanban.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BoardRequest(@NotBlank(message = "Nama kerjaan wajib diisi") @Size(max = 100,
		message = "Nama kerjaan maksimal 100 karakter") String name) {
}
