## spring data jpa

### 一. JPA

#### JPA 的介绍以及哪些开源实现

JPA（Java Persistence API）中文名 Java 持久层 API，是 JDK 5.0 注解或 XML 描述对象－关系表的映射关系，并将运行期的实体对象持久化到数据库中。

Sun 引入新的 JPA ORM 规范出于两个原因：其一，简化现有 Java EE 和 Java SE 应用开发工作；其二，Sun 希望整合 ORM 技术，实现天下归一

#### JPA 包括以下三方面的内容

- 一套 API 标准，在 javax.persistence 的包下面，用来操作实体对象，执行 CRUD 操作，框架在后台替代我们完成所有的事情，开发者从繁琐的 JDBC 和 SQL 代码中解脱出来。
- 面向对象的查询语言：Java Persistence Query Language（JPQL），这是持久化操作中很重要的一个方面，通过面向对象而非面向数据库的查询语言查询数据，避免程序的 SQL 语句紧密耦合。
- ORM（Object/Relational Metadata）元数据的映射，JPA 支持 XML 和 JDK 5.0 注解两种元数据的形式，元数据描述对象和表之间的映射关系，框架据此将实体对象持久化到数据库表中。

#### JPA 的开源实现

JPA 的宗旨是为 POJO 提供持久化标准规范，由此可见，经过这几年的实践探索，能够脱离容器独立运行，方便开发和测试的理念已经深入人心了。Hibernate 3.2+、TopLink 10.1.3 以及 OpenJPA、QueryDSL 都提供了 JPA 的实现，以及最后的 Spring 的整合 Spring Data JPA。目前互联网公司和传统公司大量使用了 JPA 的开发标准规范。

-------

### 二. Spring Data JPA 的主要类及结构图

七个大 Repository 接口：

- Repository（org.springframework.data.repository）；
- CrudRepository（org.springframework.data.repository）；
- PagingAndSortingRepository（org.springframework.data.repository）；
- JpaRepository（org.springframework.data.jpa.repository）；
- QueryByExampleExecutor（org.springframework.data.repository.query）；
- JpaSpecificationExecutor（org.springframework.data.jpa.repository）；
- QueryDslPredicateExecutor（org.springframework.data.querydsl）

两大 Repository 实现类：

- SimpleJpaRepository（org.springframework.data.jpa.repository.support）；

- QueryDslJpaRepository（org.springframework.data.jpa.repository.support）

**类的结构关系图如图所示**

------

![springdatajpa类图.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1gaq4yei4v7j30ms0d83yz.jpg)

-------

**需要了解到的类，真正的 JPA 的底层封装类**

- EntityManager（javax.persistence）；
- EntityManagerImpl（org.hibernate.jpa.internal）。

### 三. 使用

再具体工作中很多时候需要根据不同的业务返回不用的字段，如果都将一张表的字段全部查询出来的话极度影响效率，所以希望写一个根据DTO不同来返回不同的对象 代码如下

```java
public interface EnterpriseDao extends JpaRepository<Enterprise,String>,JpaSpecificationExecutor<Enterprise>{

    <T> Collection<T> findByNameIsLike(String name, Class<T> type);

}
```

```java
public class EnterpriseDTO {
    private String id;//ID
    private String name;//企业名称

    public EnterpriseDTO(String id, String name, String summary) {
        this.id = id;
        this.name = name;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

}
```

```java
//业务方调用时传入不同字段的DTO，根据自己的需要查询需要的字段。
Collection<EnterpriseDTO> enterprises = enterpriseDao.findByNameIsLike("%ceshi%",EnterpriseDTO.class);
//全部字段直接传入实体类
Collection<Enterprise> enterprises = enterpriseDao.findByNameIsLike("Matthews", Enterprise.class);
```

参考 http://www.jackzhang.cn/spring-data-jpa-guide/

