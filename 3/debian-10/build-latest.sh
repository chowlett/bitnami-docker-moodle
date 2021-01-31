time docker build -t ss-moodle:latest .
docker tag ss-moodle:latest 938158173016.dkr.ecr.ca-central-1.amazonaws.com/ss-moodle:latest
time docker push 938158173016.dkr.ecr.ca-central-1.amazonaws.com/ss-moodle:latest