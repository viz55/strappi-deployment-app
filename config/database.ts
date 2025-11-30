export default ({ env }) => {
  const client = env("DATABASE_CLIENT", "postgres");

  return {
    connection: {
      client,
      connection:
        client === "sqlite"
          ? {
              filename: env(
                "DATABASE_FILENAME",
                "/app/data/strapi.db"
              ),
            }
          : {
              host: env("DATABASE_HOST"),
              port: env.int("DATABASE_PORT"),
              database: env("DATABASE_NAME"),
              user: env("DATABASE_USERNAME"),
              password: env("DATABASE_PASSWORD"),
              ssl: env.bool("DATABASE_SSL", false)
                ? { rejectUnauthorized: false }
                : false,
            },
      useNullAsDefault: client === "sqlite",
    },
  };
};
