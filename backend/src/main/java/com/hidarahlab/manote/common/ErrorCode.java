package com.hidarahlab.manote.common;

import org.springframework.http.HttpStatus;

/**
 * Kode error yang dikirim di field {@code code}. Kode khusus Manote memakai kode HTTP
 * induknya ditambah satu digit urut, misalnya 4011 dan 4012 adalah turunan 401.
 */
public enum ErrorCode {

	BAD_REQUEST(400, HttpStatus.BAD_REQUEST, "Permintaan tidak valid"),
	VALIDATION_FAILED(4001, HttpStatus.BAD_REQUEST, "Data yang dikirim tidak valid"),
	UNAUTHENTICATED(401, HttpStatus.UNAUTHORIZED, "Silakan login terlebih dahulu"),
	INVALID_CREDENTIALS(4011, HttpStatus.UNAUTHORIZED, "User ID/email atau password salah"),
	TOKEN_INVALID(4012, HttpStatus.UNAUTHORIZED, "Sesi berakhir. Silakan login lagi."),
	FORBIDDEN(403, HttpStatus.FORBIDDEN, "Anda tidak punya akses ke data ini"),
	NOT_FOUND(404, HttpStatus.NOT_FOUND, "Data tidak ditemukan"),
	TOO_MANY_REQUESTS(429, HttpStatus.TOO_MANY_REQUESTS, "Terlalu banyak permintaan. Coba lagi nanti."),
	LOGIN_LOCKED(4291, HttpStatus.TOO_MANY_REQUESTS, "Terlalu banyak percobaan login. Coba lagi nanti."),
	INTERNAL_ERROR(500, HttpStatus.INTERNAL_SERVER_ERROR, "Terjadi kesalahan di server. Coba lagi nanti.");

	private final int code;

	private final HttpStatus httpStatus;

	private final String defaultTitle;

	ErrorCode(int code, HttpStatus httpStatus, String defaultTitle) {
		this.code = code;
		this.httpStatus = httpStatus;
		this.defaultTitle = defaultTitle;
	}

	public int code() {
		return code;
	}

	public HttpStatus httpStatus() {
		return httpStatus;
	}

	public String defaultTitle() {
		return defaultTitle;
	}

}
