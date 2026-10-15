package com.hidarahlab.manote.dashboard.dto;

import java.time.Instant;

public record DashboardSummaryResponse(NotesSummary notes, KanbanSummary kanban, TasksSummary tasks) {

	public record NotesSummary(long total, String latestTitle) {
	}

	public record KanbanSummary(long todo, long inProgress, long done) {
	}

	/**
	 * @param pending jumlah tugas yang belum selesai
	 * @param nextTitle tugas belum selesai dengan waktu mulai paling awal
	 */
	public record TasksSummary(long pending, String nextTitle, Instant nextStartAt) {
	}

}
