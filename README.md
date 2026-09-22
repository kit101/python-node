# python-node

包含 Python、Node.js、npm、Yarn 和 cnpm 的 Docker 镜像。

- [Docker Hub：kit101z/python-node](https://hub.docker.com/r/kit101z/python-node/tags)
- [GitHub Actions 构建记录](https://github.com/kit101/python-node/actions)
- [构建发布工作流](.github/workflows/docker-publish.yml)

## 使用镜像

```bash
docker pull kit101z/python-node:3.7-22.22.0
docker run --rm kit101z/python-node:3.7-22.22.0 \
  sh -ec 'python --version; node --version'
```

已发布的版本组合：

| 镜像 tag | Python | Node.js | 架构 |
| --- | --- | --- | --- |
| `3.7-22.22.0` | 3.7 | 22.22.0 | linux/amd64、linux/arm64 |
| `3.7-18.20.4` | 3.7 | 18.20.4 | linux/amd64、linux/arm64 |
| `3.7-16.20.2` | 3.7 | 16.20.2 | linux/amd64 |
| `2.7-16.20.2` | 2.7 | 16.20.2 | linux/amd64 |

优先使用固定版本 tag。`latest` 跟随 `main` 分支的 Dockerfile，并不代表最近发布的版本组合。

## 发布规则

版本分支、Git tag 和镜像 tag 统一使用 `<Python 主版本.次版本>-<Node 完整版本>`，例如 `3.7-22.22.0`。

| 操作 | 工作流行为 |
| --- | --- |
| 推送版本分支，如 `3.7-22.22.0` | 不触发构建 |
| 推送版本 Git tag，如 `3.7-22.22.0` | 构建并发布同名镜像 tag，不更新 `latest` |
| 推送 `main` | 构建并更新 `latest`，包括普通的文档提交 |

当前工作流构建 `linux/amd64`、`linux/arm64`，推送 Docker Hub 后使用 cosign 签名。登录账号为 `kit101z`，凭据由仓库 secret `DOCKER_PASSWORD` 提供。

**版本来自 Dockerfile，不会根据分支名或 tag 自动修改。必须先提交版本修改，再在该提交上打 tag。** 无需额外创建 GitHub Release；当前工作流也未配置手动触发入口。

## 新增版本

以下以已发布的 `3.7-22.22.0` 说明操作格式。实际新增时，将变量替换为尚未发布的目标版本，不要重复发布示例版本。

### 1. 准备版本分支

从干净的工作区开始：

```bash
PYTHON_VERSION=3.7
NODE_VERSION=22.22.0
IMAGE_VERSION="${PYTHON_VERSION}-${NODE_VERSION}"

git status --short
git fetch origin --tags
git ls-remote origin "refs/heads/${IMAGE_VERSION}" "refs/tags/${IMAGE_VERSION}*"
```

如果目标 Git tag 已存在，先停止并核对版本，不要强制覆盖已发布的 tag。确认是新版本后，从主分支创建版本分支：

```bash
git switch -c "$IMAGE_VERSION" origin/main
```

如果远端版本分支已存在但尚未打 tag，使用 `git switch --track "origin/${IMAGE_VERSION}"`；如果本地分支也已存在，使用 `git switch "$IMAGE_VERSION"`。

### 2. 修改 Dockerfile 中的版本

根据目标版本修改以下三项，保留其余构建步骤：

```dockerfile
FROM python:3.7
ARG NODE_MAJOR=22
ARG NODE_VERSION=22.22.0
```

`FROM` 决定 Python 版本；`NODE_MAJOR` 选择 NodeSource 仓库；`NODE_VERSION` 决定安装的 Node.js 完整版本，必须与 `NODE_MAJOR` 一致。

### 3. 提交并推送版本分支

```bash
git diff --check
git diff -- Dockerfile
git add Dockerfile
git commit -m "Build Python ${PYTHON_VERSION} with Node.js ${NODE_VERSION}"
git push -u origin "HEAD:refs/heads/${IMAGE_VERSION}"
```

### 4. 在正确提交上打 tag，触发发布

先检查待发布提交的 Dockerfile，确认包含目标版本。下面的 tag 推送会正式触发构建发布：

```bash
RELEASE_COMMIT=$(git rev-parse HEAD)
git show "${RELEASE_COMMIT}:Dockerfile"

git tag -a "$IMAGE_VERSION" "$RELEASE_COMMIT" \
  -m "Python ${PYTHON_VERSION} / Node.js ${NODE_VERSION}"
git push origin "refs/tags/${IMAGE_VERSION}"
```

分支和 tag 可以同名，推送 tag 时使用完整的 `refs/tags/` 引用，避免歧义。不要把 tag 打在尚未修改版本的旧提交上：即使构建成功，镜像名称也可能与实际 Node 版本不符。

### 5. 检查构建并验证镜像

在 [GitHub Actions](https://github.com/kit101/python-node/actions) 中确认本次运行的提交等于 `RELEASE_COMMIT`，且构建、推送、签名均成功。重跑旧的 Actions 任务仍会使用旧提交，不能代替发布新提交。

检查 manifest 中包含两种目标架构，再固定本次 digest 运行验证：

```bash
IMAGE_REF="kit101z/python-node:${IMAGE_VERSION}"
docker buildx imagetools inspect "$IMAGE_REF"
IMAGE_DIGEST=$(docker buildx imagetools inspect "$IMAGE_REF" --format '{{.Manifest.Digest}}')

for TARGET_PLATFORM in linux/amd64 linux/arm64; do
  docker run --rm --platform "$TARGET_PLATFORM" \
    "kit101z/python-node@${IMAGE_DIGEST}" \
    sh -ec 'python --version; node --version; npm --version; yarn --version; cnpm --version'
done
```

确认 Python、Node 输出与目标版本一致，且 npm、Yarn、cnpm 均可执行。跨架构运行需要模拟器，也可分别在对应架构的主机上验证。验证完成后，在主分支 README 的版本表中追加新版本。

## 维护主分支文档

当前工作流没有按文件路径过滤，向 `main` 推送 README 修改也会重新发布 `latest`。纯文档提交使用 `[skip ci]` 跳过工作流：

```bash
git commit -m "docs: update image release guide [skip ci]"
```

需要构建发布的版本提交不要加入跳过指令。具体规则见 [GitHub：跳过工作流运行](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs)。
