package com.hidarahlab.manote.common;

/**
 * Lempar dari service untuk mengembalikan error ke klien dalam bentuk {@link ApiResponse}.
 */
public class ApiException extends RuntimeException {

	private final ErrorCode errorCode;

	public ApiException(ErrorCode errorCode) {
		this(errorCode, errorCode.defaultTitle());
	}

	public ApiException(ErrorCode errorCode, String message) {
		super(message);
		this.errorCode = errorCode;
	}

	public ErrorCode getErrorCode() {
		return errorCode;
	}

}
