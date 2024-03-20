#!/bin/bash
module=$1
jar_name="${module}/target/${module}.jar"

# `mvn`: Maven的命令行工具。
# `clean`: 清理项目，删除之前构建的输出。
# `package`: 打包项目，生成可部署的目标文件（通常是JAR或WAR文件）。
# `-Dmaven.test.skip=true`: 跳过运行测试，加快构建过程。这个选项设置为true会跳过测试阶段。
# `-pl $module`: 仅构建指定模块（项目子模块），其中`$module`是模块的名称。
# `-am`: 表示构建被选模块（及其依赖模块）。这会确保项目的所有依赖模块也会被构建。
mvn clean package -Dmaven.test.skip=true -pl  $module -am
ret=$?
if [ $ret -ne 0 ];then
    echo "===== maven build failure ====="
    exit $ret
else
    echo -n "===== maven build successfully! ====="
fi

rm -rf output
mkdir output
cp $jar_name output/
