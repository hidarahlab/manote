package com.hidarahlab.manote.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * Mengubah semua error dari controller dan service menjadi {@link ApiResponse}.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

	private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

	@ExceptionHandler(ApiException.class)
	ResponseEntity<ApiResponse<Void>> handleApiException(ApiException ex) {
		return respond(ex.getErrorCode(), ex.getMessage());
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
		String message = ex.getBindingResult()
			.getFieldErrors()
			.stream()
			.findFirst()
			.map((error) -> error.getDefaultMessage())
			.orElse(ErrorCode.VALIDATION_FAILED.defaultTitle());
		return respond(ErrorCode.VALIDATION_FAILED, message);
	}

	@ExceptionHandler({ HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class })
	ResponseEntity<ApiResponse<Void>> handleUnreadableRequest(Exception ex) {
		return respond(ErrorCode.BAD_REQUEST, ErrorCode.BAD_REQUEST.defaultTitle());
	}

	@ExceptionHandler(Exception.class)
	ResponseEntity<ApiResponse<Void>> handleOther(Exception ex) {
		// Error bawaan Spring (404 alamat tidak ada, 405 metode salah, dan sejenisnya).
		if (ex instanceof ErrorResponse errorResponse) {
			HttpStatusCode status = errorResponse.getStatusCode();
			if (status.is4xxClientError()) {
				return ResponseEntity.status(status)
					.body(ApiResponse.error(status.value(), titleFor(status.value())));
			}
		}
		logger.error("Error tak terduga", ex);
		return respond(ErrorCode.INTERNAL_ERROR, ErrorCode.INTERNAL_ERROR.defaultTitle());
	}

	static String titleFor(int status) {
		return switch (status) {
			case 400 -> ErrorCode.BAD_REQUEST.defaultTitle();
			case 401 -> ErrorCode.UNAUTHENTICATED.defaultTitle();
			case 403 -> ErrorCode.FORBIDDEN.defaultTitle();
			case 404 -> "Alamat tidak ditemukan";
			case 405 -> "Metode tidak didukung untuk alamat ini";
			case 415 -> "Format permintaan tidak didukung";
			case 429 -> ErrorCode.TOO_MANY_REQUESTS.defaultTitle();
			default -> (status >= 500) ? ErrorCode.INTERNAL_ERROR.defaultTitle() : "Permintaan tidak dapat diproses";
		};
	}

	private static ResponseEntity<ApiResponse<Void>> respond(ErrorCode errorCode, String message) {
		return ResponseEntity.status(errorCode.httpStatus()).body(ApiResponse.error(errorCode.code(), message));
	}

}
