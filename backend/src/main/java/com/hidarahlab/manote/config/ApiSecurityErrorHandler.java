package com.hidarahlab.manote.config;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

import com.hidarahlab.manote.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

/**
 * Penolakan dari lapisan keamanan terjadi sebelum controller, jadi response-nya ditulis di
 * sini dengan bentuk yang sama seperti {@code ApiResponse}.
 */
@Component
public class ApiSecurityErrorHandler implements AuthenticationEntryPoint, AccessDeniedHandler {

	@Override
	public void commence(HttpServletRequest request, HttpServletResponse response,
			AuthenticationException authException) throws IOException {
		// Ada token tetapi ditolak berarti sesi berakhir; tanpa token berarti belum login.
		boolean hasToken = request.getHeader(HttpHeaders.AUTHORIZATION) != null;
		write(response, hasToken ? ErrorCode.TOKEN_INVALID : ErrorCode.UNAUTHENTICATED);
	}

	@Override
	public void handle(HttpServletRequest request, HttpServletResponse response,
			AccessDeniedException accessDeniedException) throws IOException {
		write(response, ErrorCode.FORBIDDEN);
	}

	private static void write(HttpServletResponse response, ErrorCode errorCode) throws IOException {
		response.setStatus(errorCode.httpStatus().value());
		response.setContentType(MediaType.APPLICATION_JSON_VALUE);
		response.setCharacterEncoding(StandardCharsets.UTF_8.name());
		String title = errorCode.defaultTitle().replace("\\", "\\\\").replace("\"", "\\\"");
		response.getWriter()
			.write("{\"status\":false,\"title\":\"%s\",\"code\":%d,\"data\":null}".formatted(title, errorCode.code()));
	}

}
