package com.hidarahlab.manote.common;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;

import org.springframework.boot.webmvc.error.ErrorController;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Jaring terakhir untuk error yang tidak melewati {@link GlobalExceptionHandler}, supaya
 * bentuknya tetap {@link ApiResponse}.
 */
@RestController
public class ApiErrorController implements ErrorController {

	@RequestMapping("/error")
	ResponseEntity<ApiResponse<Void>> error(HttpServletRequest request) {
		Object attribute = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
		int status = (attribute instanceof Integer value) ? value : 500;
		return ResponseEntity.status(status).body(ApiResponse.error(status, GlobalExceptionHandler.titleFor(status)));
	}

}
