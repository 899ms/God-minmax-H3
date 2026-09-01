# 推送到 GitHub

仓库已经建好，在本地执行下面的命令即可推送到
https://github.com/LIUFelix2004/God-minmax-H3

## 首次推送（仓库是空的）

```bash
cd God-minmax-H3
git init -b main
git add .
git commit -m "feat: MiniMax H3 视频生成技能与提示词库"
git remote add origin https://github.com/LIUFelix2004/God-minmax-H3.git
git push -u origin main
```

## 仓库里已经有东西了

```bash
cd God-minmax-H3
git init -b main
git remote add origin https://github.com/LIUFelix2004/God-minmax-H3.git
git fetch origin
git reset --soft origin/main        # 保留本地文件，接上远端历史
git add .
git commit -m "feat: MiniMax H3 视频生成技能与提示词库"
git push origin main
```

## 推不上去的话

- 提示要输密码 → GitHub 早就不收密码了，去
  Settings → Developer settings → Personal access tokens 生成一个 classic token
  （勾 `repo` 权限），推送时用户名填 GitHub 用户名，密码位置粘 token。
- 用 SSH 更省事：`git remote set-url origin git@github.com:LIUFelix2004/God-minmax-H3.git`
- `main` 推被拒且远端是 `master`：把命令里的 `main` 换成 `master`。

## 推完之后

在仓库页面右上角 About 里补：

- Description：`MiniMax H3（海螺 3.0）视频生成技能与提示词库 —— 把参考片拆成提示词，把提示词拼成成片`
- Topics：`minimax` `hailuo` `minimax-h3` `ai-video` `prompt-engineering` `claude-skill` `text-to-video`
