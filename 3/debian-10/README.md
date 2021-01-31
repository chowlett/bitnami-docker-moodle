# Running the bitnami moodle image

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

## Problem using Aurora as the Moodle database

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
