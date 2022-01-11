module.exports = [
  {
    name: "LOCAL",
    type: "mysql",
    host: process.env.MYSQL_HOST,
    port: 3306,
    username: process.env.MYSQL_USERNAME,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DATABASE,
    synchronize: false,
    logging: true,
    // eslint-disable-next-line prettier/prettier
    entities: ["src\frameworks\db\mysql\models\*.ts"]
  },
  {
    name: "default",
    type: "mysql",
    host: "${GITHUBACTION_HNAME}",
    port: 3306,
    username: "${GITHUBACTION_UNAME}",
    password: "${GITHUBACTION_PNAME}",
    database: "${GITHUBACTION_DNAME}",
    synchronize: false,
    logging: false,
    entities: ["src/frameworks/db/mysql/models/*.ts"],
    migrations: ["src/frameworks/db/mysql/migration/*.ts"],
    cli: {
      entitiesDir: "src/frameworks/db/mysql/models",
      migrationsDir: "src/frameworks/db/mysql/migration",
    }
  }
];
