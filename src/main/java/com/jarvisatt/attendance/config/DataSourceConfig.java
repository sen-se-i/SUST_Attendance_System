package com.jarvisatt.attendance.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.net.URI;

@Configuration
public class DataSourceConfig {

    @Bean
    @Primary
    public DataSource dataSource() {
        String dbUrl = System.getenv("SPRING_DATASOURCE_URL");
        if (dbUrl == null || dbUrl.isBlank()) {
            dbUrl = System.getenv("DATABASE_URL");
        }

        String dbHost = System.getenv("DB_HOST");
        String dbName = System.getenv("DB_NAME");
        String dbUser = System.getenv("DB_USER");
        String dbPass = System.getenv("DB_PASSWORD");
        String dbPort = System.getenv("DB_PORT");
        if (dbPort == null || dbPort.isBlank()) {
            dbPort = "5432";
        }

        if ((dbUrl == null || dbUrl.isBlank()) && dbHost != null && !dbHost.isBlank() && dbName != null && !dbName.isBlank()) {
            dbUrl = "jdbc:postgresql://" + dbHost.trim() + ":" + dbPort.trim() + "/" + dbName.trim();
        }

        HikariConfig config = new HikariConfig();

        if (dbUrl != null && !dbUrl.isBlank()) {
            if (dbUrl.startsWith("postgres://") || dbUrl.startsWith("postgresql://")) {
                try {
                    URI dbUri = new URI(dbUrl);
                    String username = dbUri.getUserInfo() != null ? dbUri.getUserInfo().split(":")[0] : "";
                    String password = dbUri.getUserInfo() != null && dbUri.getUserInfo().split(":").length > 1 ? dbUri.getUserInfo().split(":")[1] : "";
                    String host = dbUri.getHost();
                    int port = dbUri.getPort() != -1 ? dbUri.getPort() : 5432;
                    String path = dbUri.getPath();

                    String jdbcUrl = "jdbc:postgresql://" + host + ":" + port + path;
                    config.setJdbcUrl(jdbcUrl);
                    config.setUsername(username);
                    config.setPassword(password);
                    config.setDriverClassName("org.postgresql.Driver");
                } catch (Exception e) {
                    config.setJdbcUrl(dbUrl);
                }
            } else {
                config.setJdbcUrl(dbUrl);
                if (dbUser != null && !dbUser.isBlank()) config.setUsername(dbUser.trim());
                if (dbPass != null && !dbPass.isBlank()) config.setPassword(dbPass.trim());
                config.setDriverClassName("org.postgresql.Driver");
            }
        } else {

            config.setJdbcUrl("jdbc:h2:file:./data/jarvis_db;DB_CLOSE_DELAY=-1;MODE=PostgreSQL;AUTO_SERVER=TRUE");
            config.setUsername("sa");
            config.setPassword("");
            config.setDriverClassName("org.h2.Driver");
        }

        return new HikariDataSource(config);
    }
}

