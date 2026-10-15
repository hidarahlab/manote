package com.hidarahlab.manote.kanban;

import com.hidarahlab.manote.common.ApiResponse;
import com.hidarahlab.manote.kanban.dto.CardMoveRequest;
import com.hidarahlab.manote.kanban.dto.CardResponse;
import com.hidarahlab.manote.kanban.dto.CardUpdateRequest;
import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cards")
public class CardController {

	private final KanbanService kanbanService;

	public CardController(KanbanService kanbanService) {
		this.kanbanService = kanbanService;
	}

	@PutMapping("/{id}")
	public ApiResponse<CardResponse> update(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@Valid @RequestBody CardUpdateRequest request) {
		return ApiResponse.ok(kanbanService.updateCard(jwt.getSubject(), id, request));
	}

	@PutMapping("/{id}/move")
	public ApiResponse<CardResponse> move(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@Valid @RequestBody CardMoveRequest request) {
		return ApiResponse.ok(kanbanService.moveCard(jwt.getSubject(), id, request));
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
		kanbanService.deleteCard(jwt.getSubject(), id);
		return ApiResponse.ok();
	}

}
