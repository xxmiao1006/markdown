## mybatis

### 一. mybatis源码阅读环境准备

[Mybatis 源码仓库地址](https://link.zhihu.com/?target=https%3A//github.com/mybatis/mybatis-3/tree/mybatis-3.5.1)

下载后进行解压，并打开 pom 文件，查看pom 中的父级依赖

```xml
<parent>
    <groupId>org.mybatis</groupId>
    <artifactId>mybatis-parent</artifactId>
    <version>32</version>
    <relativePath />
</parent>
```

根据上述版本信息，下载 Mybatis 父级依赖 `mybatis-parent` 源码

[Mybatis-parent 源码仓库地址](https://link.zhihu.com/?target=https%3A//github.com/mybatis/parent/tree/mybatis-parent-31)

#### 1. 编译parent

```bash
# 切换到 mybatis-parent 源码目录
cd parent-mybatis-parent-31

# install
mvn clean instal
```

#### 2. 编译mybatis源码

```bash
# 切换到 mybatis 源码目录
cd mybatis-3-mybatis-3.5.1

# install 
mvn clean -Dmaven.test.skip=true install
```

修改 mybatis-3.5.1 pom 文件，**注释掉 maven-pdf-plugin**

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-pdf-plugin</artifactId>
</plugin>
```

#### 3.导入idea

