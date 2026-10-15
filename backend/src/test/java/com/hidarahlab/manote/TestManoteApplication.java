package com.hidarahlab.manote;

import org.springframework.boot.SpringApplication;

public class TestManoteApplication {

	public static void main(String[] args) {
		SpringApplication.from(ManoteApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
