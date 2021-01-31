docker run \
-it \
--rm \
-v '/Users/chowlett/.local/data/moodle/composed/moodle:/bitnami/moodle' \
-v '/Users/chowlett/.local/data/moodle/composed/moodledata:/bitnami/moodledata' \
--entrypoint /bin/sh \
ss-moodle:latest
