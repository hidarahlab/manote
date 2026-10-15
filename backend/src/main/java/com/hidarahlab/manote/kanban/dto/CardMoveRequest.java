package com.hidarahlab.manote.kanban.dto;

import com.hidarahlab.manote.kanban.CardStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * @param position urutan di kolom tujuan, mulai dari 0; lebih besar dari isi kolom berarti
 * paling bawah
 */
public record CardMoveRequest(@NotNull(message = "Kolom tujuan wajib diisi") CardStatus status,
		@NotNull(message = "Posisi wajib diisi") @Min(value = 0, message = "Posisi tidak boleh negatif") Integer position) {
}
