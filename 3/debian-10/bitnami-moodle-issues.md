# Issues Running the bitnami moodle image

## Problems with bind mounting .bitnami/moodle and /bitnami/moodledata

The following fatal error occurs in docker compose when bind mounts are configured.

### Bind Mounts

```
    volumes:
      - '/Users/chowlett/.local/data/moodle/composed/moodle:/bitnami/moodle'
      - '/Users/chowlett/.local/data/moodle/composed/moodledata:/bitnami/moodledata'
```

### Error

```
moodle_1   | chmod: changing permissions of '/bitnami/moodle': Operation not permitted
moodle_1   | chown: changing ownership of '/bitnami/moodle': Operation not permitted
bitnami-docker-moodle_moodle_1 exited with code 1
```

### Attempts to deal with this

1. chown host folders .../bitnami/moodle and ../bitnami/moodledata to 1:0, matching "daemon:root" inside the container. The latter was observed inside a correctly running docker compose that uses docker volumes rather than bind mounts.
1. chmod host folders .../bitnami/moodle and ../bitnami/moodledata to 775 (rather than 755) according to slightly related web traffic, e.g. https://github.com/bitnami/bitnami-docker-mariadb/issues/136.
1. Add privileged:true to docker-compose.yml

### Epiphany

This is actually an issue with OSX Catalina. See

1. https://stackoverflow.com/questions/58482352/operation-not-permitted-from-docker-container-logged-as-root (an observation)
1. https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/ (the fix)

I tried to fix this by giving "Full Disk Access" to Docker in Preferences/Security and Privace. Didn't work. I ended up passing on testingb this on OSX.

## DB version problem when using Aurora as the Moodle database

The symptom was an AWS ECS task failing to start, with no error message.

Setting the environment variable BITNAMI_DEBUG=true exposed the details:

```
2021-01-31T10:25:19.480-05:00   [38;5;6mmoodle [38;5;5m15:25:19.47 [0m[38;5;2mINFO [0m ==> Running Moodle install script
2021-01-31T10:25:19.900-05:00   .-..-.
2021-01-31T10:25:19.900-05:00   _____ | || |
2021-01-31T10:25:19.900-05:00   /____/-.---_ .---. .---. .-.| || | .---.
2021-01-31T10:25:19.900-05:00   | | _ _ |/ _ \/ _ \/ _ || |/ __ \
2021-01-31T10:25:19.900-05:00   * | | | | | || |_| || |_| || |_| || || |___/
2021-01-31T10:25:19.900-05:00   |_| |_| |_|\_____/\_____/\_____||_|\_____)
2021-01-31T10:25:19.900-05:00   Moodle 3.10.1 (Build: 20210118) command line installation program
2021-01-31T10:25:20.167-05:00   == Environment ==
2021-01-31T10:25:20.167-05:00   !! database mariadb (5.7.12) !!
2021-01-31T10:25:20.167-05:00   [System] version 10.2.29 is required and you are running 5.7.12 -
```

See https://github.com/bitnami/charts/issues/4540 for a writeup, with solution

The solution is to set MOODLE_DATABASE_MIN_VERSION=5.7.12

## DDL error when using Aurora as the Moodle database

```
2021-01-31T11:21:58.045-05:00   CREATE TABLE mdl_oauth2_refresh_token (
2021-01-31T11:21:58.045-05:00   id BIGINT(10) NOT NULL auto_increment,
2021-01-31T11:21:58.045-05:00   timecreated BIGINT(10) NOT NULL,
2021-01-31T11:21:58.045-05:00   timemodified BIGINT(10) NOT NULL,
2021-01-31T11:21:58.045-05:00   userid BIGINT(10) NOT NULL,
2021-01-31T11:21:58.045-05:00   issuerid BIGINT(10) NOT NULL,
2021-01-31T11:21:58.045-05:00   token LONGTEXT COLLATE utf8mb4_general_ci NOT NULL,
2021-01-31T11:21:58.045-05:00   scopehash VARCHAR(40) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
2021-01-31T11:21:58.045-05:00   CONSTRAINT PRIMARY KEY (id)
2021-01-31T11:21:58.045-05:00   , UNIQUE KEY mdl_oautrefrtoke_useisssco_uix (userid, issuerid, scopehash)
2021-01-31T11:21:58.045-05:00   , KEY mdl_oautrefrtoke_iss_ix (issuerid)
2021-01-31T11:21:58.045-05:00   , KEY mdl_oautrefrtoke_use_ix (userid)
2021-01-31T11:21:58.045-05:00   )
2021-01-31T11:21:58.045-05:00   ENGINE = InnoDB
2021-01-31T11:21:58.045-05:00   DEFAULT COLLATE = utf8mb4_general_ci ROW_FORMAT=Compressed
2021-01-31T11:21:58.045-05:00   COMMENT='Stores refresh tokens which can be exchanged for access toke'
2021-01-31T11:21:58.045-05:00   Error code: ddlexecuteerror !!
2021-01-31T11:21:58.045-05:00   !! Stack trace: * line 492 of /lib/dml/moodle_database.php: ddl_change_structure_exception thrown
2021-01-31T11:21:58.045-05:00   * line 1098 of /lib/dml/mysqli_native_moodle_database.php: call to moodle_database-&gt;query_end()
2021-01-31T11:21:58.045-05:00   * line 77 of /lib/ddl/database_manager.php: call to mysqli_native_moodle_database-&gt;change_database_structure()
2021-01-31T11:21:58.045-05:00   * line 427 of /lib/ddl/database_manager.php: call to database_manager-&gt;execute_sql_arr()
2021-01-31T11:21:58.045-05:00   * line 372 of /lib/ddl/database_manager.php: call to database_manager-&gt;install_from_xmldb_structure()
2021-01-31T11:21:58.045-05:00   * line 1795 of /lib/upgradelib.php: call to database_manager-&gt;install_from_xmldb_file()
2021-01-31T11:21:58.045-05:00   * line 479 of /lib/installlib.php: call to install_core()
2021-01-31T11:21:58.045-05:00   * line 823 of /admin/cli/install.php: call to install_cli_database()
2021-01-31T11:21:58.045-05:00   !!
```

It appears that moodle is issuing 224 "CREATE TABLE" statements, generated from an xml file that can be found in the container at /bitnami/moodle/lib/db/install.xml. There is a copy of this file in this repo at /debugging-artefacts/install.xml. The last logged statement (moodle app log) is that last table in this list - the failure(s) happened much earlier. The Aurora logs show only the first CREATE TABLE, then a couple of queries on the metadata for mdl_upgrade_log (the second table of the 224), then a couple of disconnects.

```
/aws/rds/cluster/moodle-staging/audit moodle-staging.audit.log.0.2021-01-31-18-39.0.1 1612119892307921,moodle-staging_1526730431,ss_dbuser,10.1.15.240,8,8136,QUERY,moodle_staging,'CREATE TABLE mdl_config (     id BIGINT(10) NOT NULL auto_increment,     name VARCHAR(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT \'\',     value LONGTEXT COLLATE utf8mb4_general_ci NOT NULL, CONSTRAINT  PRIMARY KEY (id) , UNIQUE KEY mdl_conf_nam_uix (name) )  ENGINE = InnoDB  DEFAULT COLLATE = utf8mb4_general_ci ROW_FORMAT=Compressed  COMMENT=\'Moodle configuration variables\' ',1709
/aws/rds/cluster/moodle-staging/audit moodle-staging.audit.log.2.2021-01-31-18-39.0.0 1612119892334668,moodle-staging_1526730431,ss_dbuser,10.1.15.240,8,8138,QUERY,moodle_staging,'SELECT column_name, data_type, character_maximum_length, numeric_precision,                        numeric_scale, is_nullable, column_type, column_default, column_key, extra                   FROM information_schema.columns                  WHERE table_name = \'mdl_upgrade_log\'                        AND table_schema = \'moodle_staging\'               ORDER BY ordinal_position',0
/aws/rds/cluster/moodle-staging/audit moodle-staging.audit.log.2.2021-01-31-18-39.0.0 1612119892335696,moodle-staging_1526730431,ss_dbuser,10.1.15.240,8,8139,QUERY,moodle_staging,'SHOW COLUMNS FROM mdl_upgrade_log',1146
/aws/rds/cluster/moodle-staging/audit moodle-staging.audit.log.3.2021-01-31-18-39.0.1 1612119892422690,moodle-staging_1526730431,ss_dbuser,10.1.3.78,7,0,DISCONNECT,moodle_staging,,0
/aws/rds/cluster/moodle-staging/audit moodle-staging.audit.log.3.2021-01-31-18-39.0.1 1612119892422880,moodle-staging_1526730431,ss_dbuser,10.1.15.240,8,0,DISCONNECT,moodle_staging,,0
```

The file throwing the exception is /bitnami/moodle/lib/dml/mysqli_native_moodle_database.php. There is a copy of this file in this repo at /debugging-artefacts/mysqli_native_moodle_database.php.

After this error, there are no tables in the database.

### Resolution

The CREATE TABLE for mdl_config (the first one executed) fails:

```
mysql> CREATE TABLE mdl_config (
    ->     id BIGINT(10) NOT NULL auto_increment,
    ->     name VARCHAR(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
    ->     value LONGTEXT COLLATE utf8mb4_general_ci NOT NULL,
    -> CONSTRAINT  PRIMARY KEY (id)
    -> , UNIQUE KEY mdl_conf_nam_uix (name)
    -> )
    ->  ENGINE = InnoDB
    ->  DEFAULT COLLATE = utf8mb4_general_ci ROW_FORMAT=Compressed
    ->  COMMENT='Moodle configuration variables'
    -> ;
ERROR 1709 (HY000): Index column size too large. The maximum column size is 767 bytes.
```

It looks like VARCHAR(255) takes 1020 bytes which exceeds the maximum column size.

Moodle executes the 224 TABLE CREATE statements as a batch then must check mdl_upgrade_log as a verification.

Workarounds described here: https://stackoverflow.com/questions/45043269/moodle-with-amazon-aurora-index-column-size-too-large-the-maximum-column-size

It looks like the problem is row format "Compressed" as described in the above. See https://dev.mysql.com/doc/refman/5.7/en/innodb-row-format.html.

Here are the values of the relevant MySQL parameers:

```
+---------------------------+-----------+
| Variable_name             | Value     |
+---------------------------+-----------+
| innodb_default_row_format | dynamic   |
| innodb_file_format        | Barracuda |
| innodb_file_format_check  | ON        |
| innodb_file_format_max    | Barracuda |
| innodb_file_per_table     | ON        |
| innodb_large_prefix       | ON        |
+--------------------------+------------+
```

With these parameters, row formats "Dynamic" and "Compressed" should both support large_prefixes, that is, index sizes of up to 3072. However Aurora serverless seems not to honour this for "Compressed". That looks like a bug.

Aurora serverless experiments with the MySQL command line:

**ROW_FORMAT=Compressed**

```
mysql> CREATE TABLE mdl_config (
    ->     id BIGINT(10) NOT NULL auto_increment,
    ->     name VARCHAR(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
    ->     value LONGTEXT COLLATE utf8mb4_general_ci NOT NULL,
    -> CONSTRAINT  PRIMARY KEY (id)
    -> , UNIQUE KEY mdl_conf_nam_uix (name)
    -> )
    ->  ENGINE = InnoDB
    ->  DEFAULT COLLATE = utf8mb4_general_ci ROW_FORMAT=Compressed
    ->  COMMENT='Moodle configuration variables'
    -> ;
ERROR 1709 (HY000): Index column size too large. The maximum column size is 767 bytes.
```

**ROW_FORMAT=Dynamic**

```
mysql> CREATE TABLE mdl_config (
    ->     id BIGINT(10) NOT NULL auto_increment,
    ->     name VARCHAR(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
    ->     value LONGTEXT COLLATE utf8mb4_general_ci NOT NULL,
    -> CONSTRAINT  PRIMARY KEY (id)
    -> , UNIQUE KEY mdl_conf_nam_uix (name)
    -> )
    ->  ENGINE = InnoDB
    ->  DEFAULT COLLATE = utf8mb4_general_ci ROW_FORMAT=Dynamic
    ->  COMMENT='Moodle configuration variables'
    -> ;
Query OK, 0 rows affected (0.07 sec)
```

Omitting ROW_FORMAT acts like "ROW_FORMAT=Dynamic", as expected.

### Workaround Attempt

The following would likely solve it but I see no place in the repo where I can add it. It would have to be added after the population of the php folder and before the initialization of the database. These two phases happened inside a 22M binary executable. No way that I can see to get control between the two phases.

```
sed -i 's/compressedrowformatsupported = true/compressedrowformatsupported = false/' mysqli_native_moodle_database.php
```

### Final Workaround

Change the character set/collate to utf8. Only two bytes wide. The initialization then works. This change is done at CREAE DATABASE time.
