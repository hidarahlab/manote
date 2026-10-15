package com.hidarahlab.manote.task;

import java.util.List;

import com.hidarahlab.manote.common.ApiResponse;
import com.hidarahlab.manote.task.dto.TaskRequest;
import com.hidarahlab.manote.task.dto.TaskResponse;
import com.hidarahlab.manote.task.dto.TaskSyncRequest;
import com.hidarahlab.manote.task.dto.TaskSyncResponse;
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
@RequestMapping("/api/tasks")
public class TaskController {

	private final TaskService taskService;

	public TaskController(TaskService taskService) {
		this.taskService = taskService;
	}

	@GetMapping
	public ApiResponse<List<TaskResponse>> list(@AuthenticationPrincipal Jwt jwt) {
		return ApiResponse.ok(taskService.list(jwt.getSubject()));
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public ApiResponse<TaskResponse> create(@AuthenticationPrincipal Jwt jwt,
			@Valid @RequestBody TaskRequest request) {
		return ApiResponse.created(taskService.create(jwt.getSubject(), request));
	}

	@PutMapping("/{id}")
	public ApiResponse<TaskResponse> update(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
			@Valid @RequestBody TaskRequest request) {
		return ApiResponse.ok(taskService.update(jwt.getSubject(), id, request));
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
		taskService.delete(jwt.getSubject(), id);
		return ApiResponse.ok();
	}

	@PostMapping("/sync")
	public ApiResponse<TaskSyncResponse> sync(@AuthenticationPrincipal Jwt jwt,
			@Valid @RequestBody TaskSyncRequest request) {
		return ApiResponse.ok(taskService.sync(jwt.getSubject(), request));
	}

}
