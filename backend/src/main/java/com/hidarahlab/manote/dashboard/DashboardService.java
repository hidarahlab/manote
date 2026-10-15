package com.hidarahlab.manote.dashboard;

import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;
import com.hidarahlab.manote.dashboard.dto.DashboardSummaryResponse;
import com.hidarahlab.manote.dashboard.dto.DashboardSummaryResponse.KanbanSummary;
import com.hidarahlab.manote.dashboard.dto.DashboardSummaryResponse.NotesSummary;
import com.hidarahlab.manote.dashboard.dto.DashboardSummaryResponse.TasksSummary;
import com.hidarahlab.manote.kanban.CardRepository;
import com.hidarahlab.manote.kanban.CardStatus;
import com.hidarahlab.manote.note.Note;
import com.hidarahlab.manote.note.NoteRepository;
import com.hidarahlab.manote.task.TaskRepository;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class DashboardService {

	private final UserRepository userRepository;

	private final NoteRepository noteRepository;

	private final CardRepository cardRepository;

	private final TaskRepository taskRepository;

	public DashboardService(UserRepository userRepository, NoteRepository noteRepository,
			CardRepository cardRepository, TaskRepository taskRepository) {
		this.userRepository = userRepository;
		this.noteRepository = noteRepository;
		this.cardRepository = cardRepository;
		this.taskRepository = taskRepository;
	}

	public DashboardSummaryResponse summary(String userId) {
		Long ownerId = userRepository.findByUserId(userId)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID))
			.getId();
		return new DashboardSummaryResponse(notesSummary(ownerId), kanbanSummary(ownerId), tasksSummary(ownerId));
	}

	private TasksSummary tasksSummary(Long ownerId) {
		long pending = taskRepository.countByOwnerIdAndDeletedAtIsNullAndDoneAtIsNull(ownerId);
		return taskRepository.findFirstByOwnerIdAndDeletedAtIsNullAndDoneAtIsNullOrderByStartAtAsc(ownerId)
			.map((next) -> new TasksSummary(pending, next.getTitle(), next.getStartAt()))
			.orElse(new TasksSummary(pending, null, null));
	}

	/**
	 * Lima kolom papan diringkas jadi tiga: belum (Backlog, Todo), dikerjakan (In Progress,
	 * Review), dan selesai (Done).
	 */
	private KanbanSummary kanbanSummary(Long ownerId) {
		long todo = 0;
		long inProgress = 0;
		long done = 0;
		for (Object[] row : cardRepository.countByOwnerAndStatus(ownerId)) {
			long count = (Long) row[1];
			switch ((CardStatus) row[0]) {
				case BACKLOG, TODO -> todo += count;
				case IN_PROGRESS, REVIEW -> inProgress += count;
				case DONE -> done += count;
			}
		}
		return new KanbanSummary(todo, inProgress, done);
	}

	private NotesSummary notesSummary(Long ownerId) {
		String latestTitle = noteRepository.findFirstByOwnerIdAndDeletedAtIsNullOrderByUpdatedAtDesc(ownerId)
			.map(Note::displayTitle)
			.orElse(null);
		return new NotesSummary(noteRepository.countByOwnerIdAndDeletedAtIsNull(ownerId), latestTitle);
	}

}
