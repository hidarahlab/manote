package com.hidarahlab.manote.note;

import java.util.List;

import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;
import com.hidarahlab.manote.note.dto.NoteRequest;
import com.hidarahlab.manote.note.dto.NoteResponse;
import com.hidarahlab.manote.note.dto.ReminderRequest;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class NoteService {

	private final NoteRepository noteRepository;

	private final UserRepository userRepository;

	public NoteService(NoteRepository noteRepository, UserRepository userRepository) {
		this.noteRepository = noteRepository;
		this.userRepository = userRepository;
	}

	public List<NoteResponse> list(String userId) {
		return noteRepository.findByOwnerIdAndDeletedAtIsNullOrderByUpdatedAtDesc(ownerId(userId))
			.stream()
			.map(NoteResponse::from)
			.toList();
	}

	public NoteResponse get(String userId, Long noteId) {
		return NoteResponse.from(findOwned(userId, noteId));
	}

	@Transactional
	public NoteResponse create(String userId, NoteRequest request) {
		Note note = new Note(ownerId(userId), request.title(), request.content());
		return NoteResponse.from(noteRepository.save(note));
	}

	@Transactional
	public NoteResponse update(String userId, Long noteId, NoteRequest request) {
		Note note = findOwned(userId, noteId);
		note.update(request.title(), request.content());
		return NoteResponse.from(note);
	}

	@Transactional
	public NoteResponse setReminder(String userId, Long noteId, ReminderRequest request) {
		Note note = findOwned(userId, noteId);
		note.setReminderAt(request.reminderAt());
		return NoteResponse.from(note);
	}

	@Transactional
	public void delete(String userId, Long noteId) {
		// Ditandai terhapus, tidak dibuang, supaya perangkat lain ikut menghapus saat sinkron.
		findOwned(userId, noteId).markDeleted();
	}

	private Note findOwned(String userId, Long noteId) {
		return noteRepository.findByIdAndOwnerIdAndDeletedAtIsNull(noteId, ownerId(userId))
			.orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "Catatan tidak ditemukan"));
	}

	private Long ownerId(String userId) {
		return userRepository.findByUserId(userId)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID))
			.getId();
	}

}
