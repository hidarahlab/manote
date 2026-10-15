package com.hidarahlab.manote.dashboard;

import com.hidarahlab.manote.common.ApiResponse;
import com.hidarahlab.manote.dashboard.dto.DashboardSummaryResponse;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

	private final DashboardService dashboardService;

	public DashboardController(DashboardService dashboardService) {
		this.dashboardService = dashboardService;
	}

	@GetMapping("/summary")
	public ApiResponse<DashboardSummaryResponse> summary(@AuthenticationPrincipal Jwt jwt) {
		return ApiResponse.ok(dashboardService.summary(jwt.getSubject()));
	}

}
