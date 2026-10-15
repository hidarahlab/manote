package com.hidarahlab.manote.note;

import java.util.List;

import com.hidarahlab.manote.common.ApiResponse;
import com.hidarahlab.manote.note.dto.NoteRequest;
import com.hidarahlab.manote.note.dto.NoteResponse;
import com.hidarahlab.manote.note.dto.NoteSyncRequest;
import com.hidarahlab.manote.note.dto.NoteSyncResponse;
import com.hidarahlab.manote.note.dto.ReminderRequest;
import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notes")
public class NoteController {

	private final NoteService noteService;

	private final NoteSyncService noteSyncService;

	public NoteController(NoteService noteService, NoteSyncService noteSyncService) {
		this.noteService = noteService;
		this.noteSyncService = noteSyncService;
	}

	@PostMapping("/sync")
	public ApiResponse<NoteSyncResponse> sync(@AuthenticationPrincipal Jwt jwt,
			@Valid @RequestBody NoteSyncRequest request) {
		return ApiResponse.ok(noteSyncService.sync(jwt.getSubject(), request));
	}

	@GetMapping
	public ApiResponse<List<NoteResponse>> list(@AuthenticationPrincipal Jwt jwt) {
		return ApiResponse.ok(noteService.list(jwt.getSubject()));
	}

	@GetMapping("/{id}")
	public ApiResponse<NoteResponse> get(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
		return ApiResponse.ok(noteService.get(jwt.getSubject(), id));
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public ApiResponse<NoteResponse> create(@AuthenticationPrincipal Jwt jwt,
			@Valid @RequestBody NoteRequest request) {
		return ApiResponse.created(noteService.create(jwt.getSubject(), request));
	}

	@PutMapping("/{id}")
	public ApiResponse<NoteResponse> update(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@Valid @RequestBody NoteRequest request) {
		return ApiResponse.ok(noteService.update(jwt.getSubject(), id, request));
	}

	@PutMapping("/{id}/reminder")
	public ApiResponse<NoteResponse> setReminder(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@RequestBody ReminderRequest request) {
		return ApiResponse.ok(noteService.setReminder(jwt.getSubject(), id, request));
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
		noteService.delete(jwt.getSubject(), id);
		return ApiResponse.ok();
	}

}
