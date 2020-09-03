## maven

### 设置本地maven的默认编码格式，默认GBK

配好MAVEN_HOME的环境变量后,在运行cmd.打开cmd 运行mvn -v命令即可

管理员权限打开cmd，设置环境变量 

```bash
setx /M MAVEN_OPTS "-Xms256m -Xmx512m -Dfile.encoding=UTF-8"
```

保存,退出cmd.重新打开cmd 运行mvn -v命令即可.

