## mybatis

### 一. mybatis源码阅读环境准备

[Mybatis 源码仓库地址](https://link.zhihu.com/?target=https%3A//github.com/mybatis/mybatis-3/tree/mybatis-3.5.1)

[Mybatis中文注释源码](https://github.com/tuguangquan/mybatis)

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



### 二. 通过一个例子了解mybatis

```java
public class Main {
    public static void main(String[] args) throws IOException {
        String resource = "mybatis-config.xml";
        InputStream inputStream = null;
        inputStream = Resources.getResourceAsStream(resource);

        SqlSessionFactory sqlSessionFactory = null;

        sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);

        SqlSession sqlSession = null;
        try {
            sqlSession = sqlSessionFactory.openSession();
            /*RoleMapper roleMapper = sqlSession.getMapper(RoleMapper.class);
            Role role = roleMapper.getRole(1L);
            System.out.println(role.getId() + ":" + role.getRoleName() + ":" + role.getNote());*/
            Role role = sqlSession.selectOne("com.mytest.mapper.RoleMapper.getRole", 1L);
            System.out.println(role);
            sqlSession.commit();

        } catch (Exception e) {
            sqlSession.rollback();
            e.printStackTrace();
        } finally {
            sqlSession.close();
        }
    }
}
```

里面出现了几个比较重要的概念

* SqlSessionFactoryBuilder：  它会根据配置信息或者代码来生成SqlSessionFactory
* SqlSessionFactory：依靠工厂来生成SqlSession
* SqlSession：是一个既可以发送sql去执行并返回结果，也可以获取mapper的接口。
* SQL Mapper：是MyBatis设计的新组件，它是一个由Java接口和XML文件（或注解）构成的，需要给出对应的SQL和映射规则。负责发送SQL去执行，并返回结果。



#### 源码解析: 构造

new SqlSessionFactoryBuilder().build(inputStream)  入口  

->  org.apache.ibatis.session.SqlSessionFactoryBuilder#build(java.io.InputStream, java.lang.String, java.util.Properties) 通过builder建立工厂  

->  org.apache.ibatis.builder.xml.XMLConfigBuilder#parse 

->  org.apache.ibatis.builder.xml.XMLConfigBuilder#parseConfiguration  解析mybatis-config.xml里面的配置

```java
  //解析配置
  private void parseConfiguration(XNode root) {
    try {
      //分步骤解析
      //issue #117 read properties first
      //1.properties
      propertiesElement(root.evalNode("properties"));
      //2.类型别名
      typeAliasesElement(root.evalNode("typeAliases"));
      //3.插件
      pluginElement(root.evalNode("plugins"));
      //4.对象工厂
      objectFactoryElement(root.evalNode("objectFactory"));
      //5.对象包装工厂
      objectWrapperFactoryElement(root.evalNode("objectWrapperFactory"));
      //6.设置
      settingsElement(root.evalNode("settings"));
      // read it after objectFactory and objectWrapperFactory issue #631
      //7.环境
      environmentsElement(root.evalNode("environments"));
      //8.databaseIdProvider
      databaseIdProviderElement(root.evalNode("databaseIdProvider"));
      //9.类型处理器
      typeHandlerElement(root.evalNode("typeHandlers"));
      //10.映射器
      mapperElement(root.evalNode("mappers"));
    } catch (Exception e) {
      throw new BuilderException("Error parsing SQL Mapper Configuration. Cause: " + e, e);
    }
  }
```

这个方法将xml不同的节点解析出来后用不同的方法进行解析，下面以mapperElement(root.evalNode("mappers"))为例

```java
//10.映射器
//	10.1使用类路径
//	<mappers>
//	  <mapper resource="org/mybatis/builder/AuthorMapper.xml"/>
//	  <mapper resource="org/mybatis/builder/BlogMapper.xml"/>
//	  <mapper resource="org/mybatis/builder/PostMapper.xml"/>
//	</mappers>
//
//	10.2使用绝对url路径
//	<mappers>
//	  <mapper url="file:///var/mappers/AuthorMapper.xml"/>
//	  <mapper url="file:///var/mappers/BlogMapper.xml"/>
//	  <mapper url="file:///var/mappers/PostMapper.xml"/>
//	</mappers>
//
//	10.3使用java类名
//	<mappers>
//	  <mapper class="org.mybatis.builder.AuthorMapper"/>
//	  <mapper class="org.mybatis.builder.BlogMapper"/>
//	  <mapper class="org.mybatis.builder.PostMapper"/>
//	</mappers>
//
//	10.4自动扫描包下所有映射器
//	<mappers>
//	  <package name="org.mybatis.builder"/>
//	</mappers>
private void mapperElement(XNode parent) throws Exception {
    if (parent != null) {
        for (XNode child : parent.getChildren()) {
            if ("package".equals(child.getName())) {
                //10.4自动扫描包下所有映射器
                String mapperPackage = child.getStringAttribute("name");
                configuration.addMappers(mapperPackage);
            } else {
                String resource = child.getStringAttribute("resource");
                String url = child.getStringAttribute("url");
                String mapperClass = child.getStringAttribute("class");
                if (resource != null && url == null && mapperClass == null) {
                    //10.1使用类路径
                    ErrorContext.instance().resource(resource);
                    InputStream inputStream = Resources.getResourceAsStream(resource);
                    //映射器比较复杂，调用XMLMapperBuilder
                    //注意在for循环里每个mapper都重新new一个XMLMapperBuilder，来解析
                    XMLMapperBuilder mapperParser = new XMLMapperBuilder(inputStream, configuration, resource, configuration.getSqlFragments());
                    mapperParser.parse();
                } else if (resource == null && url != null && mapperClass == null) {
                    //10.2使用绝对url路径
                    ErrorContext.instance().resource(url);
                    InputStream inputStream = Resources.getUrlAsStream(url);
                    //映射器比较复杂，调用XMLMapperBuilder
                    XMLMapperBuilder mapperParser = new XMLMapperBuilder(inputStream, configuration, url, configuration.getSqlFragments());
                    mapperParser.parse();
                } else if (resource == null && url == null && mapperClass != null) {
                    //10.3使用java类名
                    Class<?> mapperInterface = Resources.classForName(mapperClass);
                    //直接把这个映射加入配置
                    configuration.addMapper(mapperInterface);
                } else {
                    //这里很明显了，下面三种只能由一种配置，超过会抛异常
                    throw new BuilderException("A mapper element may only specify a url, resource or class, but not more than one.");
                }
            }
        }
    }
}
//mapperParser.parse()
//解析
public void parse() {
    //如果没有加载过再加载，防止重复加载
    if (!configuration.isResourceLoaded(resource)) {
        //配置mapper
        configurationElement(parser.evalNode("/mapper"));
        //标记一下，已经加载过了
        configuration.addLoadedResource(resource);
        //绑定映射器到namespace
        bindMapperForNamespace();
    }

    //还有没解析完的东东这里接着解析？
    parsePendingResultMaps();
    parsePendingChacheRefs();
    parsePendingStatements();
}


//配置mapper元素 解析mapper文件里面的节点
//	<mapper namespace="org.mybatis.example.BlogMapper">
//	  <select id="selectBlog" parameterType="int" resultType="Blog">
//	    select * from Blog where id = #{id}
//	  </select>
//	</mapper>
private void configurationElement(XNode context) {
    try {
        //1.配置namespace 这个很重要，后期mybatis会通过这个动态代理我们的Mapper接口
        String namespace = context.getStringAttribute("namespace");
        if (namespace.equals("")) {
            throw new BuilderException("Mapper's namespace cannot be empty");
        }
        builderAssistant.setCurrentNamespace(namespace);
        //2.配置cache-ref
        cacheRefElement(context.evalNode("cache-ref"));
        //3.配置cache
        cacheElement(context.evalNode("cache"));
        
        //4.配置parameterMap(已经废弃,老式风格的参数映射)
        parameterMapElement(context.evalNodes("/mapper/parameterMap"));
        //5.配置resultMap(高级功能)  <resultMap></resultMap>
        resultMapElements(context.evalNodes("/mapper/resultMap"));
        
        
        
        //6.配置sql(定义可重用的 SQL 代码段)
        //<sql id="staticSql">select * from test</sql> （可重用的代码段）
        //<select> <include refid="staticSql"></select>
        sqlElement(context.evalNodes("/mapper/sql"));
        //7.//解析增删改查节点<select> <insert> <update> <delete>
        buildStatementFromContext(context.evalNodes("select|insert|update|delete"));
        
        
    } catch (Exception e) {
        throw new BuilderException("Error parsing Mapper XML. Cause: " + e, e);
    }
}
```

在这个parse()方法中，调用了一个configuationElement代码，用于解析XXXMapper.xml文件中的各种节点，包括`<cache>`、`<cache-ref>`、`<paramaterMap>`（已过时）、`<resultMap>`、`<sql>`、还有增删改查节点，和上面相同的是，我们也挑一个主要的来说，因为解析过程都大同小异。毋庸置疑的是，我们在XXXMapper.xml中必不可少的就是编写SQL，与数据库交互主要靠的也就是这个，所以着重说说解析增删改查节点的方法——buildStatementFromContext()。在没贴代码之前，根据这个名字就可以略知一二了，这个方法会根据我们的增删改查节点，来构造一个Statement，而用过原生Jdbc的都知道，Statement就是我们操作数据库的对象。

```java
//7.配置select|insert|update|delete
private void buildStatementFromContext(List<XNode> list) {
    //调用7.1构建语句
    if (configuration.getDatabaseId() != null) {
        buildStatementFromContext(list, configuration.getDatabaseId());
    }
    buildStatementFromContext(list, null);
}

//7.1构建语句
private void buildStatementFromContext(List<XNode> list, String requiredDatabaseId) {
    for (XNode context : list) {
        //构建所有语句,一个mapper下可以有很多select
        //语句比较复杂，核心都在这里面，所以调用XMLStatementBuilder
        final XMLStatementBuilder statementParser = new XMLStatementBuilder(configuration, builderAssistant, context, requiredDatabaseId);
        try {
            //核心XMLStatementBuilder.parseStatementNode
            statementParser.parseStatementNode();
        } catch (IncompleteElementException e) {
            //如果出现SQL语句不完整，把它记下来，塞到configuration去
            configuration.addIncompleteStatement(statementParser);
        }
    }
}

//解析语句(select|insert|update|delete)
//<select
//  id="selectPerson"
//  parameterType="int"
//  parameterMap="deprecated"
//  resultType="hashmap"
//  resultMap="personResultMap"
//  flushCache="false"
//  useCache="true"
//  timeout="10000"
//  fetchSize="256"
//  statementType="PREPARED"
//  resultSetType="FORWARD_ONLY">
//  SELECT * FROM PERSON WHERE ID = #{id}
//</select>
public void parseStatementNode() {
    String id = context.getStringAttribute("id");
    String databaseId = context.getStringAttribute("databaseId");

    //如果databaseId不匹配，退出
    if (!databaseIdMatchesCurrent(id, databaseId, this.requiredDatabaseId)) {
        return;
    }

    //暗示驱动程序每次批量返回的结果行数
    Integer fetchSize = context.getIntAttribute("fetchSize");
    //超时时间
    Integer timeout = context.getIntAttribute("timeout");
    //引用外部 parameterMap,已废弃
    String parameterMap = context.getStringAttribute("parameterMap");
    //参数类型
    String parameterType = context.getStringAttribute("parameterType");
    Class<?> parameterTypeClass = resolveClass(parameterType);
    //引用外部的 resultMap(高级功能)
    String resultMap = context.getStringAttribute("resultMap");
    //结果类型
    String resultType = context.getStringAttribute("resultType");
    //脚本语言,mybatis3.2的新功能
    String lang = context.getStringAttribute("lang");
    //得到语言驱动
    LanguageDriver langDriver = getLanguageDriver(lang);

    Class<?> resultTypeClass = resolveClass(resultType);
    //结果集类型，FORWARD_ONLY|SCROLL_SENSITIVE|SCROLL_INSENSITIVE 中的一种
    String resultSetType = context.getStringAttribute("resultSetType");
    //语句类型, STATEMENT|PREPARED|CALLABLE 的一种
    StatementType statementType = StatementType.valueOf(context.getStringAttribute("statementType", StatementType.PREPARED.toString()));
    ResultSetType resultSetTypeEnum = resolveResultSetType(resultSetType);

    //获取命令类型(select|insert|update|delete)
    String nodeName = context.getNode().getNodeName();
    SqlCommandType sqlCommandType = SqlCommandType.valueOf(nodeName.toUpperCase(Locale.ENGLISH));
    boolean isSelect = sqlCommandType == SqlCommandType.SELECT;
    boolean flushCache = context.getBooleanAttribute("flushCache", !isSelect);
    //是否要缓存select结果
    boolean useCache = context.getBooleanAttribute("useCache", isSelect);
    //仅针对嵌套结果 select 语句适用：如果为 true，就是假设包含了嵌套结果集或是分组了，这样的话当返回一个主结果行的时候，就不会发生有对前面结果集的引用的情况。
    //这就使得在获取嵌套的结果集的时候不至于导致内存不够用。默认值：false。
    boolean resultOrdered = context.getBooleanAttribute("resultOrdered", false);

    // Include Fragments before parsing
    //解析之前先解析<include>SQL片段
    XMLIncludeTransformer includeParser = new XMLIncludeTransformer(configuration, builderAssistant);
    includeParser.applyIncludes(context.getNode());

    // Parse selectKey after includes and remove them.
    //解析之前先解析<selectKey>
    processSelectKeyNodes(id, parameterTypeClass, langDriver);

    // Parse the SQL (pre: <selectKey> and <include> were parsed and removed)
    //解析成SqlSource，一般是DynamicSqlSource
    SqlSource sqlSource = langDriver.createSqlSource(configuration, context, parameterTypeClass);
    String resultSets = context.getStringAttribute("resultSets");
    //(仅对 insert 有用) 标记一个属性, MyBatis 会通过 getGeneratedKeys 或者通过 insert 语句的 selectKey 子元素设置它的值
    String keyProperty = context.getStringAttribute("keyProperty");
    //(仅对 insert 有用) 标记一个属性, MyBatis 会通过 getGeneratedKeys 或者通过 insert 语句的 selectKey 子元素设置它的值
    String keyColumn = context.getStringAttribute("keyColumn");
    KeyGenerator keyGenerator;
    String keyStatementId = id + SelectKeyGenerator.SELECT_KEY_SUFFIX;
    keyStatementId = builderAssistant.applyCurrentNamespace(keyStatementId, true);
    if (configuration.hasKeyGenerator(keyStatementId)) {
        keyGenerator = configuration.getKeyGenerator(keyStatementId);
    } else {
        keyGenerator = context.getBooleanAttribute("useGeneratedKeys",
                                                   configuration.isUseGeneratedKeys() && SqlCommandType.INSERT.equals(sqlCommandType))
            ? new Jdbc3KeyGenerator() : new NoKeyGenerator();
    }

    //又去调助手类
    builderAssistant.addMappedStatement(id, sqlSource, statementType, sqlCommandType,
                                        fetchSize, timeout, parameterMap, parameterTypeClass, resultMap, resultTypeClass,
                                        resultSetTypeEnum, flushCache, useCache, resultOrdered,
                                        keyGenerator, keyProperty, keyColumn, databaseId, langDriver, resultSets);
}


//增加映射语句，存在Map里
//org.apache.ibatis.session.Configuration
protected final Map<String, MappedStatement> mappedStatements = 
   new StrictMap<MappedStatement>("Mapped Statements collection");

public MappedStatement addMappedStatement(
    String id,
    SqlSource sqlSource,
    StatementType statementType,
    SqlCommandType sqlCommandType,
    Integer fetchSize,
    Integer timeout,
    String parameterMap,
    Class<?> parameterType,
    String resultMap,
    Class<?> resultType,
    ResultSetType resultSetType,
    boolean flushCache,
    boolean useCache,
    boolean resultOrdered,
    KeyGenerator keyGenerator,
    String keyProperty,
    String keyColumn,
    String databaseId,
    LanguageDriver lang,
    String resultSets) {

    if (unresolvedCacheRef) {
        throw new IncompleteElementException("Cache-ref not yet resolved");
    }

    //为id加上namespace前缀
    id = applyCurrentNamespace(id, false);
    //是否是select语句
    boolean isSelect = sqlCommandType == SqlCommandType.SELECT;

    //又是建造者模式
    MappedStatement.Builder statementBuilder = new MappedStatement.Builder(configuration, id, sqlSource, sqlCommandType);
    statementBuilder.resource(resource);
    statementBuilder.fetchSize(fetchSize);
    statementBuilder.statementType(statementType);
    statementBuilder.keyGenerator(keyGenerator);
    statementBuilder.keyProperty(keyProperty);
    statementBuilder.keyColumn(keyColumn);
    statementBuilder.databaseId(databaseId);
    statementBuilder.lang(lang);
    statementBuilder.resultOrdered(resultOrdered);
    statementBuilder.resulSets(resultSets);
    setStatementTimeout(timeout, statementBuilder);

    //1.参数映射
    setStatementParameterMap(parameterMap, parameterType, statementBuilder);
    //2.结果映射
    setStatementResultMap(resultMap, resultType, resultSetType, statementBuilder);
    setStatementCache(isSelect, flushCache, useCache, currentCache, statementBuilder);

    MappedStatement statement = statementBuilder.build();
    //建造好调用configuration.addMappedStatement
    configuration.addMappedStatement(statement);
    return statement;
}
```

这个代码段虽然很长，但是一句话形容它就是繁琐但不复杂，里面主要也就是对xml的节点进行解析。MyBatis需要做的就是，先判断这个节点是用来干什么的，然后再获取这个节点的id、parameterType、resultType等属性，封装成一个MappedStatement对象，由于这个对象很复杂，所以MyBatis使用了构造者模式来构造这个对象，最后当MappedStatement对象构造完成后，将其封装到Configuration对象中。

代码执行至此，基本就结束了对Configuration对象的构建，MyBatis的第一阶段：构造，也就到这里结束了



#### 源码解析: 执行











[手把手教你阅读mybatis源码](https://www.cnblogs.com/javazhiyin/p/12340498.html)