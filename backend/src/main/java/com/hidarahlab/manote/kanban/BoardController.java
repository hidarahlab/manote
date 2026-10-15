package com.hidarahlab.manote.kanban;

import java.util.List;

import com.hidarahlab.manote.common.ApiResponse;
import com.hidarahlab.manote.kanban.dto.BoardDetailResponse;
import com.hidarahlab.manote.kanban.dto.BoardRequest;
import com.hidarahlab.manote.kanban.dto.BoardResponse;
import com.hidarahlab.manote.kanban.dto.CardCreateRequest;
import com.hidarahlab.manote.kanban.dto.CardResponse;
import com.hidarahlab.manote.kanban.dto.KanbanSyncRequest;
import com.hidarahlab.manote.kanban.dto.KanbanSyncResponse;
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
@RequestMapping("/api/boards")
public class BoardController {

	private final KanbanService kanbanService;

	private final KanbanSyncService kanbanSyncService;

	public BoardController(KanbanService kanbanService, KanbanSyncService kanbanSyncService) {
		this.kanbanService = kanbanService;
		this.kanbanSyncService = kanbanSyncService;
	}

	@PostMapping("/sync")
	public ApiResponse<KanbanSyncResponse> sync(@AuthenticationPrincipal Jwt jwt,
			@Valid @RequestBody KanbanSyncRequest request) {
		return ApiResponse.ok(kanbanSyncService.sync(jwt.getSubject(), request));
	}

	@GetMapping
	public ApiResponse<List<BoardResponse>> list(@AuthenticationPrincipal Jwt jwt) {
		return ApiResponse.ok(kanbanService.listBoards(jwt.getSubject()));
	}

	@GetMapping("/{id}")
	public ApiResponse<BoardDetailResponse> get(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
		return ApiResponse.ok(kanbanService.getBoard(jwt.getSubject(), id));
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public ApiResponse<BoardResponse> create(@AuthenticationPrincipal Jwt jwt,
			@Valid @RequestBody BoardRequest request) {
		return ApiResponse.created(kanbanService.createBoard(jwt.getSubject(), request));
	}

	@PutMapping("/{id}")
	public ApiResponse<BoardResponse> rename(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@Valid @RequestBody BoardRequest request) {
		return ApiResponse.ok(kanbanService.renameBoard(jwt.getSubject(), id, request));
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
		kanbanService.deleteBoard(jwt.getSubject(), id);
		return ApiResponse.ok();
	}

	@PostMapping("/{id}/cards")
	@ResponseStatus(HttpStatus.CREATED)
	public ApiResponse<CardResponse> createCard(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@Valid @RequestBody CardCreateRequest request) {
		return ApiResponse.created(kanbanService.createCard(jwt.getSubject(), id, request));
	}

}
