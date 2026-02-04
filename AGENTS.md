- 执行测试用例命令需要进入对应前后端的目录
- client 目录是flutter的前端，支持android和ios
- server 目录是基于spring-boot3 reactive技术栈的后端，要求所有请求都用reactive的语法编写
- design 目录是设计稿文件地址
- 如果需要查看具体需求，可以在 `@docs/BRD.md` 和 `@docs/PRD.md` 中查找


Reactive 特定规则：

必须使用 StepVerifier.create().expectNext().verifyComplete()
禁止在测试中使用 .block()
所有数据库操作返回 Mono 或 Flux
