以下是一份常用的 Git 命令速查表，按日常使用场景分类，方便快速查阅。

---

### 配置

| 命令                                      | 说明                     |
| --------------------------------------- | ---------------------- |
| `git config --global user.name "你的名字"`  | 设置全局用户名                |
| `git config --global user.email "你的邮箱"` | 设置全局邮箱                 |
| `git config --global --list`            | 查看全局配置                 |
| `git config --global alias.co checkout` | 设置别名（例：co 代替 checkout） |

---

### 创建与克隆仓库

| 命令                         | 说明      |
| -------------------------- | ------- |
| `git init`                 | 初始化本地仓库 |
| `git clone <url>`          | 克隆远程仓库  |
| `git clone -b <分支名> <url>` | 克隆指定分支  |

---

### 查看状态与历史

| 命令                                 | 说明            |
| ---------------------------------- | ------------- |
| `git status`                       | 查看工作区与暂存区状态   |
| `git log`                          | 查看提交历史        |
| `git log --oneline`                | 每条提交一行简要显示    |
| `git log --graph --all --decorate` | 图形化展示所有分支历史   |
| `git diff`                         | 查看工作区未暂存的改动   |
| `git diff --staged`                | 查看已暂存但未提交的改动  |
| `git show <commit>`                | 查看某次提交的详细内容   |
| `git blame <file>`                 | 查看文件每行的修改者与提交 |

---

### 暂存与提交

| 命令                    | 说明                  |
| --------------------- | ------------------- |
| `git add <file>`      | 将文件添加到暂存区           |
| `git add .`           | 暂存当前目录所有修改          |
| `git commit -m "信息"`  | 提交暂存区内容             |
| `git commit -am "信息"` | 暂存并提交（仅限已跟踪的文件）     |
| `git commit --amend`  | 修改上一次提交（可编辑说明或补充文件） |
| `git rm <file>`       | 删除文件并暂存删除操作         |
| `git mv <old> <new>`  | 移动/重命名文件并暂存         |

---

### 分支操作

| 命令                         | 说明            |
| -------------------------- | ------------- |
| `git branch`               | 列出本地分支        |
| `git branch -r`            | 列出远程分支        |
| `git branch <分支名>`         | 创建新分支         |
| `git branch -d <分支名>`      | 安全删除分支（已合并）   |
| `git branch -D <分支名>`      | 强制删除分支        |
| `git checkout <分支名>`       | 切换到已有分支       |
| `git checkout -b <分支名>`    | 创建并切换到新分支     |
| `git switch <分支名>`         | （较新语法）切换分支    |
| `git switch -c <分支名>`      | （较新语法）创建并切换   |
| `git merge <分支名>`          | 合并指定分支到当前分支   |
| `git rebase <分支名>`         | 变基到指定分支       |
| `git cherry-pick <commit>` | 提取某次提交应用到当前分支 |

---

### 远程协作

| 命令                               | 说明                  |
| -------------------------------- | ------------------- |
| `git remote -v`                  | 查看远程仓库地址            |
| `git remote add <简称> <url>`      | 添加远程仓库（通常简称 origin） |
| `git fetch <远程>`                 | 拉取远程所有更新（不合并）       |
| `git pull <远程> <分支>`             | 拉取并合并远程分支           |
| `git pull --rebase`              | 以变基方式拉取（保持历史线性）     |
| `git push <远程> <分支>`             | 推送本地分支到远程           |
| `git push -u origin <分支>`        | 首次推送并建立跟踪关系         |
| `git push origin --delete <分支名>` | 删除远程分支              |

---

### 撤销与回退

| 命令                             | 说明               |
| ------------------------------ | ---------------- |
| `git restore <file>`           | 放弃工作区修改（以暂存区为准）  |
| `git restore --staged <file>`  | 取消暂存，保留工作区改动     |
| `git reset --soft HEAD~1`      | 撤销最近一次提交，改动回到暂存区 |
| `git reset --mixed HEAD~1`（默认） | 撤销提交，改动回到工作区     |
| `git reset --hard HEAD~1`      | 彻底丢弃最近一次提交及修改 ⚠️ |
| `git revert <commit>`          | 生成一次反向提交，安全撤销历史  |
| `git clean -fd`                | 删除未跟踪的文件和目录      |

---

### 贮藏（临时保存工作）

| 命令                | 说明             |
| ----------------- | -------------- |
| `git stash`       | 贮藏当前改动，恢复干净工作区 |
| `git stash pop`   | 恢复最近一次贮藏并删除记录  |
| `git stash apply` | 恢复并保留贮藏记录      |
| `git stash list`  | 查看贮藏列表         |
| `git stash drop`  | 删除某个贮藏         |

---

### 标签

| 命令                        | 说明        |
| ------------------------- | --------- |
| `git tag`                 | 列出标签      |
| `git tag -a v1.0 -m "说明"` | 创建附注标签    |
| `git push origin --tags`  | 推送所有标签到远程 |
| `git push origin <标签名>`   | 推送单个标签    |

---
