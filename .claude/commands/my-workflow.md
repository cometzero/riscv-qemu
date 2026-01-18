---
description: Created with Workflow Studio
allowed-tools: Task,AskUserQuestion
---
```mermaid
flowchart TD
    start_node_default([시작])
    end_node_default([종료])

```

## 워크플로 실행 가이드

위의 Mermaid 플로우차트를 따라 워크플로를 실행하세요. 각 노드 유형의 실행 방법은 아래에 설명되어 있습니다.

### 노드 유형별 실행 방법

- **사각형 노드**: Task 도구를 사용하여 서브 에이전트 실행
- **다이아몬드 노드(AskUserQuestion:...)**: AskUserQuestion 도구를 사용하여 사용자에게 질문하고 응답에 따라 분기
- **다이아몬드 노드(Branch/Switch:...)**: 이전 처리 결과에 따라 자동으로 분기(세부 정보 섹션 참조)
- **사각형 노드(Prompt 노드)**: 아래 세부 정보 섹션에 설명된 프롬프트 실행
