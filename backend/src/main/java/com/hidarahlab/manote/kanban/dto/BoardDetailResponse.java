package com.hidarahlab.manote.kanban.dto;

import java.util.List;

/**
 * @param cards semua kartu, urut per kolom lalu per posisi
 */
public record BoardDetailResponse(Long id, String name, List<CardResponse> cards) {
}
