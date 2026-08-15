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
                String user = System.getenv("DB_USER");
                String pass = System.getenv("DB_PASSWORD");
                if (user != null) config.setUsername(user);
                if (pass != null) config.setPassword(pass);
            }
        } else {
            // Local H2 fallback with persistent file database
            config.setJdbcUrl("jdbc:h2:file:./data/jarvis_db;DB_CLOSE_DELAY=-1;MODE=PostgreSQL;AUTO_SERVER=TRUE");
            config.setUsername("sa");
            config.setPassword("");
            config.setDriverClassName("org.h2.Driver");
        }

        return new HikariDataSource(config);
    }
}
