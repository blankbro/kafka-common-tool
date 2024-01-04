#!/bin/bash
name="spring-boot-kafka"
jar_name="spring-boot-kafka.jar"
deploy_path="/root/github/kafka-test-tool/client-test_java/output"
filePah="${deploy_path}/${jar_name}"
envi="local"
java_opts=""
application_properties=""
Start() {
    java $java_opts -jar ${filePah} -Dfile.encoding=utf-8 --spring.profiles.active=${envi} ${application_properties} -Djava.security.egd=file:/dev/./urandom --name=${name} &>/dev/null
}
Stop() {
    pid=$(ps -ef | grep -n "java.*--name=${name}" | grep -v grep | grep -v kill | awk '{print $2}')
    if [ ${pid} ]; then
        kill ${tpid}
        for ((i = 0; i < 10; ++i)); do
            sleep 1
            pid=$(ps -ef | grep -n "java.*--name=${name}" | grep -v grep | grep -v kill | awk '{print $2}')
            if [ ${tpid} ]; then
                echo -e ".\c"
            else
                echo 'Stop Success!'
                break
            fi
        done
        pid=$(ps -ef | grep -n "java.*--name=${name}" | grep -v grep | grep -v kill | awk '{print $2}')
        if [ ${pid} ]; then
            echo 'Kill Process!'
            kill -9 ${pid}
        fi
    else
        echo 'App already stop!'
    fi

}
case $1 in
"start")
    Start
    ;;
"stop")
    Stop
    ;;
"restart")
    Stop
    Start
    ;;
*)
    echo "unknown command"
    exit 1
    ;;
esac
