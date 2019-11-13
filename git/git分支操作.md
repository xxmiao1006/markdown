## git分支操作

### 1.创建本地分支与远程分支

创建本地分支并切换到本地分支

```bash
git checkout -b feat-{0.1}-{测试}
```

![创建并切换远程分支.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7xhs3lhghj30c704nq2z.jpg)

将本地分支推送到远程分支

```bash
git push origin feat-{0.1}-{测试}:feat-{0.1}-{测试}
```

![将本地分支推送到远程分支.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7xhxz50rjj30gn07z3z4.jpg)

用以下两个命令可以将本地分支与远程分支关联

```bash
git push --set-upstream origin feat-{0.1}-{测试}
git branch --set-upstream-to=origin/feat-{0.1}-{测试} feat-{0.1}-{测试}
```

![本地分支关联远程分支.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7xi11sqlhj30st09cwfg.jpg)

如果远程新建了一个分支，本地没有该分支

```bash
git pull
git checkout --track origin/feat-{0.1}-{测试}
```

### 2. 其他命令

切换分支

```bash
git checkout feat-{0.1}-{测试}
```

删除本地分支

```bash
git branch -d feat-{0.1}-{测试}
```

查看所有本地分支和远程分支

```bash
git branch -a
```

删除远程分支

推送一个空分支到远程 即删除远程分支

```
git branch -r -d origin/feat-{0.1}-{测试}
git push origin :feat-{0.1}-{测试}
```

