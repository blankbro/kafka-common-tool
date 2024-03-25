#!/bin/bash

# 提前设置好 kafka_bin_dir 环境变量

kafka_bin_dir="."
mm2_properties=""
operation=""

# 解析命令行参数
# $# 是一个特殊变量，表示命令行参数的数量。-gt 是一个比较运算符，表示大于。
while [[ $# -gt 0 ]]; do
    # 将当前处理的命令行参数赋值给变量 key
    key="$1"

    case $key in
    --kafka-bin-dir)
        kafka_bin_dir="$2"
        shift
        shift
        ;;
    --mm2-properties)
        mm2_properties="$2"
        shift
        shift
        ;;
    --operation)
        operation="$2"
        shift
        shift
        ;;
    *)
        shift
        ;;
    esac
done

Stop(){
    pid=$(ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh' | awk '{print $2}')
    if [ -n "${pid}" ]; then
        echo "kill ${pid}"
        kill ${pid}
        for ((i=0; i<10; ++i)) do
            sleep 1
            pid=$(ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh' | awk '{print $2}')
            if [ -n "${pid}" ]; then
                echo -e ".\c"
            else
                echo 'Stop Success!'
                break;
            fi
        done

        pid=$(ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh' | awk '{print $2}')
        if [ -n "${pid}" ]; then
          echo "kill -9 ${pid}"
          kill -9 ${pid}
        fi
    else
        echo "进程已关闭"
    fi
}

Start(){
    pid=$(ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh' | awk '{print $2}')
    # -n: string is not empty
    # -z: string is empty
    if [ -n "${pid}" ]; then
        echo "进程已启动"
        exit 0
    fi

    echo "开始启动"

    # 不再控制台打印任何日志: &>/dev/null 相当于 >/dev/null 2>&1
    # 后台启动: &
    echo "sh ${kafka_bin_dir}/connect-mirror-maker.sh ${mm2_properties} &>/dev/null &"
    sh ${kafka_bin_dir}/connect-mirror-maker.sh ${mm2_properties} &>/dev/null &

    for ((i=0; i<10; ++i)) do
        sleep 1
        pid=$(ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh' | awk '{print $2}')
        if [ -z "${pid}" ]; then
            echo -e ".\c"
        else
            echo 'Start Success!'
            break;
        fi
    done

    pid=$(ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh' | awk '{print $2}')
    if [ -z "${pid}" ]; then
      echo '启动失败'
    fi
}

Ps(){
    ps -ef | grep "${mm2_properties}" | grep -Ev 'grep|kill|mm2\.sh'
}

case $operation in
    "ps" )
        Ps
    ;;
    "start" )
        Start
    ;;
    "stop" )
       Stop
    ;;
    "restart" )
       Stop
       Start
    ;;
    * )
        echo "unknown command"
        exit 1
    ;;
esac