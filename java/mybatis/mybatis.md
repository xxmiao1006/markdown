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

sqlSession = sqlSessionFactory.openSession(); 入口

根据之前我们得到了一个SqlSessionFactory对象，下一步就是要去获取SqlSession对象，这里会调用SqlSessionFactory.openSession()方法来获取，而openSession中实际上就是对SqlSession做了进一步的加工封装，包括增加了事务、执行器等

```java
private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
    Transaction tx = null;
    try {
      final Environment environment = configuration.getEnvironment();
      final TransactionFactory transactionFactory = getTransactionFactoryFromEnvironment(environment);
      //通过事务工厂来产生一个事务
      tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
      //生成一个执行器(事务包含在执行器里)
      final Executor executor = configuration.newExecutor(tx, execType);
      //然后产生一个DefaultSqlSession
      return new DefaultSqlSession(configuration, executor, autoCommit);
    } catch (Exception e) {
      //如果打开事务出错，则关闭它
      closeTransaction(tx); // may have fetched a connection so lets call close()
      throw ExceptionFactory.wrapException("Error opening session.  Cause: " + e, e);
    } finally {
      //最后清空错误上下文
      ErrorContext.instance().reset();
    }
  }
```

到这里可以得出的小结论是，SqlSessionFactory对象中由于存在Configuration对象，所以它保存了**全局配置信息，以及初始化环境和DataSource**，而DataSource的作用就是用来开辟链接，当我们调用openSession方法时，就会开辟一个连接对象并传给SqlSession对象，交给SqlSession来**对数据库做相关操作**。

MyBatis底层使用了动态代理，我们实际上调用的是MyBatis为我们生成的代理对象。我们在获取Mapper的时候，需要调用SqlSession的getMapper()方法，那么就从这里深入。

sqlSession.getMapper(RoleMapper.class) ; 入口  最终会调用到下面

```java
//getMapper方法最终会调用到这里，这个是MapperRegistry的getMapper方法
@SuppressWarnings("unchecked")
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
    //MapperProxyFactory  在解析的时候会生成一个map  map中会有我们的DemoMapper的Class
    final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
    if (mapperProxyFactory == null) {
        throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
    }
    try {
        return mapperProxyFactory.newInstance(sqlSession);
    } catch (Exception e) {
        throw new BindingException("Error getting mapper instance. Cause: " + e, e);
    }
}
```

可以看到这里mapperProxyFactory对象会从一个叫做knownMappers的对象中以**type**为key取出值，这个knownMappers是一个HashMap，存放了我们的DemoMapper对象，而这里的type，就是我们上面写的Mapper接口。那么就有人会问了，这个knownMappers是在什么时候生成的呢？实际上在解析的时候，会调用parse()方法,相信大家都还记得，这个方法内部有一个bindMapperForNamespace方法，而就是这个方法帮我们完成了knownMappers的生成，并且将我们的Mapper接口put进去。

```java
public void parse() {
    //判断文件是否之前解析过
    if (!configuration.isResourceLoaded(resource)) {
        //解析mapper文件
        configurationElement(parser.evalNode("/mapper"));
        configuration.addLoadedResource(resource);
        //这里：绑定Namespace里面的Class对象*
        bindMapperForNamespace();
    }

    //重新解析之前解析不了的节点
    parsePendingResultMaps();
    parsePendingCacheRefs();
    parsePendingStatements();
}
private void bindMapperForNamespace() {
    String namespace = builderAssistant.getCurrentNamespace();
    if (namespace != null) {
        Class<?> boundType = null;
        try {
            boundType = Resources.classForName(namespace);
        } catch (ClassNotFoundException e) {
        }
        if (boundType != null) {
            if (!configuration.hasMapper(boundType)) {
                configuration.addLoadedResource("namespace:" + namespace);
                //这里将接口class传入
                configuration.addMapper(boundType);
            }
        }
    }
}
public <T> void addMapper(Class<T> type) {
    if (type.isInterface()) {
        if (hasMapper(type)) {
            throw new BindingException("Type " + type + " is already known to the MapperRegistry.");
        }
        boolean loadCompleted = false;
        try {
            //这里将接口信息put进konwMappers。
            knownMappers.put(type, new MapperProxyFactory<>(type));
            MapperAnnotationBuilder parser = new MapperAnnotationBuilder(config, type);
            parser.parse();
            loadCompleted = true;
        } finally {
            if (!loadCompleted) {
                knownMappers.remove(type);
            }
        }
    }
}
```

所以我们在getMapper之后，获取到的是一个Class，之后的代码就简单了，就是生成标准的代理类了，调用newInstance()方法。

```java
public T newInstance(SqlSession sqlSession) {
    //首先会调用这个newInstance方法
    //动态代理逻辑在MapperProxy里面
    final MapperProxy<T> mapperProxy = new MapperProxy<>(sqlSession, mapperInterface, methodCache);
    //通过这里调用下面的newInstance方法
    return newInstance(mapperProxy);
}
@SuppressWarnings("unchecked")
protected T newInstance(MapperProxy<T> mapperProxy) {
    //jdk自带的动态代理
    return (T) Proxy.newProxyInstance(mapperInterface.getClassLoader(), new Class[] { mapperInterface }, mapperProxy);
}
```

到这里，就完成了**代理对象**（**MapperProxy**）的创建，很明显的，MyBatis的底层就是对我们的接口进行代理类的实例化，从而操作数据库。但是，我们好像就得到了一个空荡荡的对象，调用方法的逻辑呢？好像根本就没有看到，所以这也是比较考验Java功底的地方。我们知道，一个类如果要称为代理对象，那么一定需要实现InvocationHandler接口，并且实现其中的invoke方法，进行一波推测，逻辑一定在invoke方法中。于是就可以点进MapperProxy类，发现其的确实现了InvocationHandler接口，这里我将一些用不到的代码先删除了，只留下有用的代码，便于分析

```java
/**
 * @author Clinton Begin
 * @author Eduardo Macarron
 */
public class MapperProxy<T> implements InvocationHandler, Serializable {

    public MapperProxy(SqlSession sqlSession, Class<T> mapperInterface, Map<Method, MapperMethod> methodCache) {
        //构造
        this.sqlSession = sqlSession;
        this.mapperInterface = mapperInterface;
        this.methodCache = methodCache;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        //这就是一个很标准的JDK动态代理了
        //执行的时候会调用invoke方法
        try {
            if (Object.class.equals(method.getDeclaringClass())) {
                //判断方法所属的类
                //是不是调用的Object默认的方法
                //如果是  则不代理，不改变原先方法的行为
                return method.invoke(this, args);
            } else if (method.isDefault()) {
                //对于默认方法的处理
                //判断是否为default方法，即接口中定义的默认方法。
                //如果是接口中的默认方法则把方法绑定到代理对象中然后调用。
                //这里不详细说
                if (privateLookupInMethod == null) {
                    return invokeDefaultMethodJava8(proxy, method, args);
                } else {
                    return invokeDefaultMethodJava9(proxy, method, args);
                }
            }
        } catch (Throwable t) {
            throw ExceptionUtil.unwrapThrowable(t);
        }
        //如果不是默认方法，则真正开始执行MyBatis代理逻辑。
        //获取MapperMethod代理对象
        final MapperMethod mapperMethod = cachedMapperMethod(method);
        //执行
        return mapperMethod.execute(sqlSession, args);
    }

    private MapperMethod cachedMapperMethod(Method method) {
        //动态代理会有缓存，computeIfAbsent 如果缓存中有则直接从缓存中拿
        //如果缓存中没有，则new一个然后放入缓存中
        //因为动态代理是很耗资源的
        return methodCache.computeIfAbsent(method, k -> new MapperMethod(mapperInterface, method, sqlSession.getConfiguration()));
    }
}
```

在方法开始代理之前，首先会先判断是否调用了Object类的方法，如果是，那么MyBatis不会去改变其行为，直接返回，如果是默认方法，则绑定到代理对象中然后调用（不是本文的重点），如果都不是，那么就是我们定义的mapper接口方法了，那么就开始执行。执行方法需要一个**MapperMethod**对象，这个对象是MyBatis执行方法逻辑使用的，MyBatis这里获取MapperMethod对象的方式是，首先去**方法缓存**中看看是否已经存在了，如果不存在则new一个然后存入缓存中，因为创建代理对象是十分消耗资源的操作。总而言之，这里会得到一个MapperMethod对象，然后通过MapperMethod的excute()方法，来真正地执行逻辑。

```java
//execute() 这里是真正执行SQL的地方
public Object execute(SqlSession sqlSession, Object[] args) {
    //判断是哪一种SQL语句
    Object result;
    switch (command.getType()) {
        case INSERT: {
            Object param = method.convertArgsToSqlCommandParam(args);
            result = rowCountResult(sqlSession.insert(command.getName(), param));
            break;
        }
        case UPDATE: {
            Object param = method.convertArgsToSqlCommandParam(args);
            result = rowCountResult(sqlSession.update(command.getName(), param));
            break;
        }
        case DELETE: {
            Object param = method.convertArgsToSqlCommandParam(args);
            result = rowCountResult(sqlSession.delete(command.getName(), param));
            break;
        }
        case SELECT:
            //我们的例子是查询

            //判断是否有返回值
            if (method.returnsVoid() && method.hasResultHandler()) {
                //无返回值
                executeWithResultHandler(sqlSession, args);
                result = null;
            } else if (method.returnsMany()) {
                //返回值多行 这里调用这个方法
                result = executeForMany(sqlSession, args);
            } else if (method.returnsMap()) {
                //返回Map
                result = executeForMap(sqlSession, args);
            } else if (method.returnsCursor()) {
                //返回Cursor
                result = executeForCursor(sqlSession, args);
            } else {
                Object param = method.convertArgsToSqlCommandParam(args);
                result = sqlSession.selectOne(command.getName(), param);
                if (method.returnsOptional()
                    && (result == null || !method.getReturnType().equals(result.getClass()))) {
                    result = Optional.ofNullable(result);
                }
            }
            break;
        case FLUSH:
            result = sqlSession.flushStatements();
            break;
        default:
            throw new BindingException("Unknown execution method for: " + command.getName());
    }
    if (result == null && method.getReturnType().isPrimitive() && !method.returnsVoid()) {
        throw new BindingException("Mapper method '" + command.getName()
                                   + " attempted to return null from a method with a primitive return type (" + method.getReturnType() + ").");
    }
    return result;
}

//返回值多行 这里调用这个方法
private <E> Object executeForMany(SqlSession sqlSession, Object[] args) {
    //返回值多行时执行的方法
    List<E> result;
    //param是我们传入的参数，如果传入的是Map，那么这个实际上就是Map对象
    Object param = method.convertArgsToSqlCommandParam(args);
    if (method.hasRowBounds()) {
        //如果有分页
        RowBounds rowBounds = method.extractRowBounds(args);
        //执行SQL的位置
        result = sqlSession.selectList(command.getName(), param, rowBounds);
    } else {
        //如果没有
        //执行SQL的位置
        result = sqlSession.selectList(command.getName(), param);
    }
    // issue #510 Collections & arrays support
    if (!method.getReturnType().isAssignableFrom(result.getClass())) {
        if (method.getReturnType().isArray()) {
            return convertToArray(result);
        } else {
            return convertToDeclaredCollection(sqlSession.getConfiguration(), result);
        }
    }
    return result;
}

/**
  *  获取参数名的方法
  */
public Object getNamedParams(Object[] args) {
    final int paramCount = names.size();
    if (args == null || paramCount == 0) {
        //如果传过来的参数是空
        return null;
    } else if (!hasParamAnnotation && paramCount == 1) {
        //如果参数上没有加注解例如@Param，且参数只有一个，则直接返回参数
        return args[names.firstKey()];
    } else {
        //如果参数上加了注解，或者参数有多个。
        //那么MyBatis会封装参数为一个Map，但是要注意，由于jdk的原因，我们只能获取到参数下标和参数名，但是参数名会变成arg0,arg1.
        //所以传入多个参数的时候，最好加@Param，否则假设传入多个String，会造成#{}获取不到值的情况
        final Map<String, Object> param = new ParamMap<>();
        int i = 0;
        for (Map.Entry<Integer, String> entry : names.entrySet()) {
            //entry.getValue 就是参数名称
            param.put(entry.getValue(), args[entry.getKey()]);
            //如果传很多个String，也可以使用param1，param2.。。
            // add generic param names (param1, param2, ...)
            final String genericParamName = GENERIC_NAME_PREFIX + String.valueOf(i + 1);
            // ensure not to overwrite parameter named with @Param
            if (!names.containsValue(genericParamName)) {
                param.put(genericParamName, args[entry.getKey()]);
            }
            i++;
        }
        return param;
    }
}
```





[手把手教你阅读mybatis源码](https://www.cnblogs.com/javazhiyin/p/12340498.html)