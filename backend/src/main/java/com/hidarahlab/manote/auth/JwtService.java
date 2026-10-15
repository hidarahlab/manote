package com.hidarahlab.manote.auth;

import java.time.Duration;
import java.time.Instant;

import com.hidarahlab.manote.user.User;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

	private final JwtEncoder jwtEncoder;

	private final Duration expiration;

	public JwtService(JwtEncoder jwtEncoder, @Value("${manote.jwt.expiration}") Duration expiration) {
		this.jwtEncoder = jwtEncoder;
		this.expiration = expiration;
	}

	public String createAccessToken(User user) {
		Instant now = Instant.now();
		JwtClaimsSet claims = JwtClaimsSet.builder()
			.subject(user.getUserId())
			.issuedAt(now)
			.expiresAt(now.plus(expiration))
			.claim("userType", user.getUserType().name())
			.build();
		JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
		return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
	}

	public long expiresInSeconds() {
		return expiration.toSeconds();
	}

}
