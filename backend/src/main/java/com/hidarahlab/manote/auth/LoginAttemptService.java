package com.hidarahlab.manote.auth;

import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Membatasi tebak-tebakan password: setelah beberapa kali gagal berturut-turut, login
 * untuk username itu ditolak sementara. Disimpan di memori, jadi hilang saat restart.
 */
@Service
public class LoginAttemptService {

	private static final int MAX_TRACKED_USERNAMES = 10_000;

	private record Attempts(int failures, Instant lockedUntil) {

		boolean isLocked(Instant now) {
			return lockedUntil != null && now.isBefore(lockedUntil);
		}

	}

	private final Map<String, Attempts> attemptsByUsername = new ConcurrentHashMap<>();

	private final int maxFailures;

	private final Duration lockDuration;

	public LoginAttemptService(@Value("${manote.login.max-failures}") int maxFailures,
			@Value("${manote.login.lock-duration}") Duration lockDuration) {
		this.maxFailures = maxFailures;
		this.lockDuration = lockDuration;
	}

	public void assertNotLocked(String username) {
		Attempts attempts = attemptsByUsername.get(key(username));
		Instant now = Instant.now();
		if (attempts != null && attempts.isLocked(now)) {
			long minutes = Math.max(1, Duration.between(now, attempts.lockedUntil()).toMinutes() + 1);
			throw new ApiException(ErrorCode.LOGIN_LOCKED,
					"Terlalu banyak percobaan login. Coba lagi dalam " + minutes + " menit.");
		}
	}

	public void recordFailure(String username) {
		Instant now = Instant.now();
		if (attemptsByUsername.size() >= MAX_TRACKED_USERNAMES) {
			attemptsByUsername.values().removeIf((attempts) -> !attempts.isLocked(now));
		}
		attemptsByUsername.compute(key(username), (key, attempts) -> {
			// Kunci yang sudah lewat tidak dihitung lagi.
			int failures = (attempts == null || attempts.lockedUntil() != null) ? 1 : attempts.failures() + 1;
			return new Attempts(failures, (failures >= maxFailures) ? now.plus(lockDuration) : null);
		});
	}

	public void reset(String username) {
		attemptsByUsername.remove(key(username));
	}

	private static String key(String username) {
		return username.strip().toLowerCase(Locale.ROOT);
	}

}
