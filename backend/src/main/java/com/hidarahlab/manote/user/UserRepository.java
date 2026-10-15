package com.hidarahlab.manote.user;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

	Optional<User> findByUserId(String userId);

	Optional<User> findByUserIdIgnoreCaseOrEmailIgnoreCase(String userId, String email);

}
